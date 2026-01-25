defmodule EzyHomeAppWeb.InventoryLive.Index do
  use EzyHomeAppWeb, :live_view
  alias EzyHomeApp.Inventory
  alias EzyHomeApp.Inventory.Schemas.Product # Necesitamos el struct vacío

  import EzyHomeAppWeb.CoreComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(products: Inventory.list_products())
     |> assign(bundles: Inventory.list_bundles_with_stock())
     |> assign(:product_to_sell, nil)
     |> assign(:bundle_to_sell, nil)}
  end

  # 1. Parámetros en la URL (Manejo de estados del Modal)
  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Nuevo Producto")
    |> assign(:product, %Product{}) # Pasamos un producto vacío al formulario
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Editar Producto")
    |> assign(:product, Inventory.get_product!(id)) # Buscamos el producto por ID
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Inventario")
    |> assign(:product, nil)
    |> assign(:product_to_sell, nil)
    |> assign(:bundle_to_sell, nil)
  end

  # 2. Mensaje que recibimos cuando el Formulario guarda exitosamente
  @impl true
  def handle_info({:saved, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_patch(to: ~p"/inventory") # Cierra el modal volviendo a /inventory
     |> assign(products: Inventory.list_products())} # Refresca la lista
  end

  # 3. Evento del botón "Nuevo Producto"
  @impl true
  def handle_event("new_product", _, socket) do
    # Cambiamos la URL a /inventory/new sin recargar la página
    {:noreply, push_patch(socket, to: ~p"/inventory/new")}
  end

  @impl true
  def handle_event("inc_stock", %{"id" => id}, socket) do
    product = Inventory.get_product!(id)

    # Aumentamos en 1
    {:ok, _updated_product} = Inventory.update_product(product, %{current_stock: product.current_stock + 1})

    # IMPORTANTE: Recargamos productos Y packs para ver el impacto en tiempo real
    {:noreply,
     socket
     |> assign(products: Inventory.list_products())
     |> assign(bundles: Inventory.list_bundles_with_stock())}
  end

  @impl true
  def handle_event("dec_stock", %{"id" => id}, socket) do
    product = Inventory.get_product!(id)

    if product.current_stock > 0 do
      {:ok, _updated_product} = Inventory.update_product(product, %{current_stock: product.current_stock - 1})
    end

    {:noreply,
     socket
     |> assign(products: Inventory.list_products())
     |> assign(bundles: Inventory.list_bundles_with_stock())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    product = Inventory.get_product!(id)
    {:ok, _} = Inventory.delete_product(product)

    {:noreply,
     socket
     |> put_flash(:info, "Producto eliminado correctamente.")
     |> assign(products: Inventory.list_products())
     |> assign(bundles: Inventory.list_bundles_with_stock())} # Recargamos packs por si el producto era parte de uno
  end

  @impl true
  def handle_event("sell_pack", %{"id" => id}, socket) do
    case Inventory.sell_bundle(id) do
      {:ok, _result} ->
        # SI VENDEMOS, TODO CAMBIA:
        # 1. Bajó el stock físico de los productos.
        # 2. Bajó el stock virtual de este pack.
        # 3. Pudo bajar el stock virtual de OTROS packs que compartan ingredientes.

        # Por eso, recargamos ambas listas:
        {:noreply,
         socket
         |> put_flash(:info, "¡Venta registrada! Stock descontado.")
         |> assign(:products, Inventory.list_products()) # Refresca tabla de arriba
         |> assign(:bundles, Inventory.list_bundles_with_stock())} # Refresca tabla de abajo

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Error: #{reason}")}
    end
  end

  @impl true
  def handle_event("open_sell_modal", %{"id" => id}, socket) do
    product = Inventory.get_product!(id)
    {:noreply, assign(socket, :product_to_sell, product)}
  end

  # CERRAR MODAL: Cuando cancelas
  @impl true
  def handle_event("close_sell_modal", _, socket) do
    {:noreply, assign(socket, :product_to_sell, nil)}
  end

  def handle_event("prepare_sale", %{"id" => id}, socket) do
    product = Inventory.get_product!(id)
    # Guardamos el producto en el socket y activamos el modal
    {:noreply, assign(socket, :selling_product, product)}
  end

  # 2. Cuando el modal envía el formulario con la cantidad
  @impl true
  def handle_event("confirm_sale", %{"quantity" => quantity}, socket) do
    product = socket.assigns.product_to_sell
    qty = String.to_integer(quantity)

    case Inventory.sell_product(product.id, qty) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Venta registrada: #{qty} x #{product.name}")
         |> assign(:product_to_sell, nil) # Cerramos el modal
         |> assign(products: Inventory.list_products()) # Refrescamos listas
         |> assign(bundles: Inventory.list_bundles_with_stock())}

      {:error, msg} ->
        # Si hay error, mantenemos el modal abierto pero mostramos el error
        {:noreply, put_flash(socket, :error, msg)}
    end
  end

  # Para cerrar el modal sin hacer nada
  def handle_event("cancel_sale", _, socket) do
    {:noreply, assign(socket, :selling_product, nil)}
  end

  @impl true
  def handle_event("open_sell_bundle_modal", %{"id" => id}, socket) do
    # Buscamos el pack en la lista que ya tenemos cargada (es más eficiente)
    bundle = Enum.find(socket.assigns.bundles, fn b -> b.id == String.to_integer(id) end)
    {:noreply, assign(socket, :bundle_to_sell, bundle)}
  end

  # 2. Confirmar Venta de Pack
  @impl true
  def handle_event("confirm_bundle_sale", %{"quantity" => quantity}, socket) do
    bundle = socket.assigns.bundle_to_sell
    qty = String.to_integer(quantity)

    # Llamamos a tu función de vender pack (Inventory.sell_bundle)
    # Nota: Asumo que sell_bundle acepta (id, user_id, quantity).
    case Inventory.sell_bundle(bundle.id, qty) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Venta de Pack registrada (#{qty} u). Stock descontado.")
         |> assign(:bundle_to_sell, nil) # Cerramos modal
         |> assign(products: Inventory.list_products()) # Refrescamos productos
         |> assign(bundles: Inventory.list_bundles_with_stock())} # Refrescamos packs

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, "Error: #{msg}")}
    end
  end
end
