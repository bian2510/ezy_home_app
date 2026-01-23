defmodule EzyHomeAppWeb.InventoryLive.ShowBundle do
  use EzyHomeAppWeb, :live_view
  alias EzyHomeApp.Inventory

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    bundle = Inventory.get_bundle!(id)

    {:ok,
     socket
     |> assign(:page_title, "Armando Pack: #{bundle.name}")
     |> assign(:bundle, bundle)
     |> assign(:search_query, "")
     |> assign(:search_results, [])}
  end

  # --- EVENTOS ---

  # 1. Buscar mientras escribes
  @impl true
  def handle_event("search", params, socket) do

    query = params["value"] || params["query"] || ""

    results = if query == "", do: [], else: Inventory.search_products(query)
    {:noreply, assign(socket, search_results: results, search_query: query)}
  end

  # 2. Click en "+" para agregar producto
  @impl true
  def handle_event("add_item", %{"product-id" => product_id}, socket) do
    case Inventory.add_item_to_bundle(socket.assigns.bundle.id, product_id) do
      {:ok, _item} ->
        # Recargamos el bundle para ver el nuevo item en la lista
        bundle = Inventory.get_bundle!(socket.assigns.bundle.id)

        {:noreply,
         socket
         |> put_flash(:info, "Producto agregado al pack.")
         |> assign(:bundle, bundle)
         |> assign(:search_results, []) # Limpiamos búsqueda
         |> assign(:search_query, "")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Este producto ya está en el pack.")}
    end
  end

  # 3. Click en "Quitar"
  @impl true
  def handle_event("remove_item", %{"id" => item_id}, socket) do
    Inventory.remove_item_from_bundle(item_id)
    bundle = Inventory.get_bundle!(socket.assigns.bundle.id)
    {:noreply, assign(socket, :bundle, bundle)}
  end

  # Evento para RESTAR cantidad (-)
  @impl true
  def handle_event("dec_qty", %{"id" => item_id}, socket) do
    Inventory.dec_item_quantity(item_id)
    # Recargamos para ver el cambio
    {:noreply, refresh_bundle(socket, socket.assigns.bundle.id)}
  end

  # --- VISTA HTML ---
  @impl true
  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-5xl px-4 py-6">
      <div class="mb-8 border-b border-gray-200 pb-4">
        <h1 class="text-3xl font-bold text-gray-900"><%= @bundle.name %></h1>
        <div class="mt-2 flex items-center gap-4 text-sm text-gray-500">
          <span class="bg-gray-100 px-2 py-1 rounded">SKU: <%= @bundle.sku %></span>
          <span>Precio: $<%= @bundle.price %></span>
        </div>
      </div>

      <div class="grid grid-cols-1 gap-8 md:grid-cols-2">

        <div class="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <h2 class="mb-4 text-lg font-semibold text-gray-800">📦 Contenido del Pack</h2>

          <%= if Enum.empty?(@bundle.bundle_items) do %>
            <div class="py-10 text-center text-gray-500 bg-gray-50 rounded-lg border-2 border-dashed border-gray-200">
              Este pack está vacío.<br>Agrega productos desde la derecha. 👉
            </div>
          <% else %>
            <ul class="divide-y divide-gray-100">
              <li :for={item <- @bundle.bundle_items} class="flex items-center justify-between py-3 px-2 hover:bg-gray-50 rounded-lg transition-colors">
                <div class="flex-1">
                  <p class="font-medium text-gray-900"><%= item.product.name %></p>
                  <p class="text-xs text-gray-500">SKU: <%= item.product.sku %></p>
                </div>
                <div class="flex items-center gap-2 mx-4 bg-white border border-gray-200 rounded-md shadow-sm">
                  <button
                    phx-click="dec_qty"
                    phx-value-id={item.id}
                    class="px-2 py-1 text-gray-500 hover:text-indigo-600 hover:bg-gray-100 rounded-l-md font-bold disabled:opacity-50"
                    disabled={item.quantity <= 1}
                  >
                    -
                  </button>
                  <span class="w-8 text-center text-sm font-semibold text-gray-900 select-none">
                    <%= item.quantity %>
                  </span>
                  <button
                    phx-click="add_item"
                    phx-value-product-id={item.product_id}
                    class="px-2 py-1 text-gray-500 hover:text-indigo-600 hover:bg-gray-100 rounded-r-md font-bold"
                  >
                    +
                  </button>
                </div>
                <button
                  phx-click="remove_item"
                  phx-value-id={item.id}
                  class="text-gray-400 hover:text-red-600 p-2 rounded-full hover:bg-red-50 transition-colors"
                  title="Eliminar ingrediente"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
                    <path fill-rule="evenodd" d="M8.75 1A2.75 2.75 0 006 3.75v.443c-.795.077-1.584.176-2.365.298a.75.75 0 10.23 1.482l.149-.022.841 10.518A2.75 2.75 0 007.596 19h4.807a2.75 2.75 0 002.742-2.53l.841-10.52.149.023a.75.75 0 00.23-1.482A41.03 41.03 0 0014 4.193V3.75A2.75 2.75 0 0011.25 1h-2.5zM10 4c.84 0 1.673.025 2.5.075V3.75c0-.69-.56-1.25-1.25-1.25h-2.5c-.69 0-1.25.56-1.25 1.25v.325C8.327 4.025 9.16 4 10 4zM8.58 7.72a.75.75 0 00-1.5.06l.3 7.5a.75.75 0 101.5-.06l-.3-7.5zm4.34.06a.75.75 0 10-1.5-.06l-.3 7.5a.75.75 0 101.5.06l.3-7.5z" clip-rule="evenodd" />
                  </svg>
                </button>
              </li>
            </ul>
          <% end %>
        </div>

        <div class="rounded-lg border border-gray-200 bg-gray-50 p-6">
          <h2 class="mb-4 text-lg font-semibold text-gray-800">🔍 Buscar Productos</h2>

          <input
            type="text"
            placeholder="Escribe nombre o SKU..."
            value={@search_query}
            phx-keyup="search"
            phx-debounce="300"
            class="w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 text-gray-900 bg-white placeholder:text-gray-400"
          />

          <%= if @search_results != [] do %>
            <ul class="mt-4 divide-y divide-gray-200 rounded-md border border-gray-200 bg-white shadow-sm">
              <li :for={product <- @search_results} class="flex items-center justify-between p-3 hover:bg-gray-50">
                <div class="overflow-hidden">
                  <p class="truncate text-sm font-medium text-gray-900"><%= product.name %></p>
                  <p class="text-xs text-gray-500"><%= product.sku %></p>
                </div>
                <button
                  phx-click="add_item"
                  phx-value-product-id={product.id}
                  class="ml-2 rounded-full bg-indigo-600 p-1 text-white hover:bg-indigo-500"
                >
                  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" class="w-5 h-5">
                    <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
                  </svg>
                </button>
              </li>
            </ul>
          <% end %>
        </div>

      </div>

      <div class="mt-8">
        <.link navigate={~p"/inventory"} class="text-indigo-600 font-medium hover:underline">
          &larr; Volver al listado
        </.link>
      </div>
    </div>
    """
  end

  defp refresh_bundle(socket, bundle_id) do
    bundle = Inventory.get_bundle!(bundle_id)
    virtual_stock = Inventory.calculate_bundle_stock(bundle)

    socket
    |> assign(:bundle, bundle)
    |> assign(:virtual_stock, virtual_stock) # <--- Guardamos el número en el socket
  end
end
