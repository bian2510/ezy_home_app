defmodule EzyHomeAppWeb.InventoryLive.Index do
  use EzyHomeAppWeb, :live_view
  alias EzyHomeApp.Inventory
  alias EzyHomeApp.Inventory.Schemas.Product # Necesitamos el struct vacío

  import EzyHomeAppWeb.CoreComponents

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, products: Inventory.list_products(), bundles: Inventory.list_bundles_with_stock())}
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

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Inventario")
    |> assign(:product, nil)
  end

  # 2. Evento del botón "Nuevo Producto"
  @impl true
  def handle_event("new_product", _, socket) do
    # Cambiamos la URL a /inventory/new sin recargar la página
    {:noreply, push_patch(socket, to: ~p"/inventory/new")}
  end

  # 3. Mensaje que recibimos cuando el Formulario guarda exitosamente
  @impl true
  def handle_info({:saved, message}, socket) do
    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_patch(to: ~p"/inventory") # Cierra el modal volviendo a /inventory
     |> assign(products: Inventory.list_products())} # Refresca la lista
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
end
