defmodule EzyHomeAppWeb.InventoryLive.Index do
  use EzyHomeAppWeb, :live_view

  # Usamos los módulos específicos ahora
  alias EzyHomeApp.Inventory.Products
  # alias EzyHomeApp.Inventory.Bundles (Lo usaremos pronto)
  alias EzyHomeApp.Sales
  alias EzyHomeApp.Inventory.Schemas.Product

  import EzyHomeAppWeb.CoreComponents

  @impl true
  def mount(_params, _session, socket) do
    # 1. Extraemos el usuario y su empresa
    user = socket.assigns.current_scope.user
    company_id = user.company_id

    {:ok,
     socket
     |> assign(:current_user, user)
     |> assign(:current_company_id, company_id) # <--- GUARDAMOS EL ID AQUÍ
     |> assign(products: Products.list(company_id)) # <--- FILTRAMOS POR EMPRESA
     # NOTA: Esto fallará hasta que arreglemos Bundles, pero déjalo así por ahora:
     # |> assign(bundles: Bundles.list_with_stock(company_id))
     |> assign(bundles: []) # Dejo esto vacío temporalmente para que no crashee ya mismo
     |> assign(:product_to_sell, nil)
     |> assign(:bundle_to_sell, nil)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    company_id = socket.assigns.current_company_id

    socket
    |> assign(:page_title, "Nuevo Producto")
    # Inicializamos el producto con la empresa ya asignada
    |> assign(:product, %Product{company_id: company_id})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    company_id = socket.assigns.current_company_id

    socket
    |> assign(:page_title, "Editar Producto")
    # Seguridad: Buscamos usando ID y Company ID
    |> assign(:product, Products.get!(company_id, id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Inventario")
    |> assign(:product, nil)
    |> assign(:product_to_sell, nil)
    |> assign(:bundle_to_sell, nil)
  end

  @impl true
  def handle_info({:saved, message}, socket) do
    company_id = socket.assigns.current_company_id

    {:noreply,
     socket
     |> put_flash(:info, message)
     |> push_patch(to: ~p"/inventory")
     |> assign(products: Products.list(company_id))} # Recargar lista segura
  end

  @impl true
  def handle_event("new_product", _, socket) do
    {:noreply, push_patch(socket, to: ~p"/inventory/new")}
  end

  @impl true
  def handle_event("inc_stock", %{"id" => id}, socket) do
    company_id = socket.assigns.current_company_id
    # Obtenemos producto seguro
    product = Products.get!(company_id, id)

    # Aquí no cambia mucho, la lógica interna de update ya maneja el changeset
    {:ok, _updated_product} = Products.update(product, %{current_stock: product.current_stock + 1})

    {:noreply,
     socket
     |> assign(products: Products.list(company_id))
     # |> assign(bundles: Bundles.list_with_stock(company_id)) # Descomentar luego
     }
  end

  @impl true
  def handle_event("dec_stock", %{"id" => id}, socket) do
    company_id = socket.assigns.current_company_id
    product = Products.get!(company_id, id)

    if product.current_stock > 0 do
      {:ok, _updated_product} = Products.update(product, %{current_stock: product.current_stock - 1})
    end

    {:noreply,
     socket
     |> assign(products: Products.list(company_id))
     # |> assign(bundles: Bundles.list_with_stock(company_id)) # Descomentar luego
     }
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    company_id = socket.assigns.current_company_id

    # 1. Seguridad Anti-Borrado Ajeno
    product = Products.get!(company_id, id)
    {:ok, _} = Products.delete(product)

    {:noreply,
     socket
     |> put_flash(:info, "Producto eliminado correctamente.")
     |> assign(products: Products.list(company_id))
     # |> assign(bundles: Bundles.list_with_stock(company_id)) # Descomentar luego
     }
  end

  # ... (La lógica de ventas de Packs/Bundles está comentada o simplificada
  # hasta que arreglemos el archivo de Bundles, para que compile ahora) ...

  @impl true
  def handle_event("open_sell_modal", %{"id" => id}, socket) do
    company_id = socket.assigns.current_company_id
    # Seguridad al abrir modal
    product = Products.get!(company_id, id)
    {:noreply, assign(socket, :product_to_sell, product)}
  end

  @impl true
  def handle_event("close_sell_modal", _, socket) do
    {:noreply, assign(socket, :product_to_sell, nil)}
  end

  @impl true
  def handle_event("confirm_sale", %{"quantity" => quantity}, socket) do
    product = socket.assigns.product_to_sell
    qty = String.to_integer(quantity)
    user = socket.assigns.current_user
    company_id = socket.assigns.current_company_id

    # Sales.record_sale ya recibe el usuario, y el usuario tiene el company_id dentro.
    # Así que Sales sabrá a quién pertenece la venta.
    case Sales.record_sale(user, :product, product.id, qty) do
      {:ok, _sale} ->
        {:noreply,
         socket
         |> put_flash(:info, "✅ Venta registrada correctamente.")
         |> assign(:product_to_sell, nil)
         |> assign(products: Products.list(company_id))} # Refresh seguro

      {:error, msg} ->
        {:noreply, put_flash(socket, :error, "❌ Error: #{inspect(msg)}")}
    end
  end

  # ... (Mantén tus otros handlers de packs/bundles aquí abajo si quieres,
  # pero recuerda que fallarán si llaman a Inventory.list_bundles) ...
end
