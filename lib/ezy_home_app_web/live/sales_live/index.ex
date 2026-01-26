defmodule EzyHomeAppWeb.SalesLive.Index do
  use EzyHomeAppWeb, :live_view
  alias EzyHomeApp.Sales

  def mount(_params, _session, socket) do
    # Traemos todas las ventas
    sales = Sales.list_sales()

    {:ok,
     socket
     |> assign(:page_title, "Historial de Ventas")
     |> assign(:sales, sales)}
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 sm:px-6 lg:px-8 py-8">
      <h1 class="text-2xl font-bold mb-6">💰 Historial de Ventas</h1>

      <div class="overflow-hidden shadow ring-1 ring-black ring-opacity-5 sm:rounded-lg">
        <table class="min-w-full divide-y divide-gray-300">
          <thead class="bg-gray-50">
            <tr>
              <th class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900">Fecha</th>
              <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Vendedor</th>
              <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Item Vendido</th>
              <th class="px-3 py-3.5 text-left text-sm font-semibold text-gray-900">Cant.</th>
              <th class="px-3 py-3.5 text-right text-sm font-semibold text-gray-900">Total</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-200 bg-white">
            <tr :for={sale <- @sales}>
              <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm text-gray-500">
                <%= Calendar.strftime(sale.inserted_at, "%d/%m/%Y %H:%M") %>
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-900">
                <%= if sale.user, do: sale.user.email, else: "Sistema" %>
              </td>
              <td class="px-3 py-4 text-sm text-gray-500">
                <%= cond do %>
                  <% sale.product -> %>
                    <div class="flex items-center gap-2">
                      <span class="text-xl">📦</span>
                      <span class="font-medium text-gray-900"><%= sale.product.name %></span>
                    </div>
                    <div class="text-xs text-gray-400 pl-7"><%= sale.product.sku %></div>

                  <% sale.bundle -> %>
                    <div class="flex items-center gap-2">
                      <span class="text-xl">🎁</span>
                      <span class="font-medium text-indigo-700"><%= sale.bundle.name %></span>
                    </div>

                    <div class="mt-2 pl-2 border-l-2 border-indigo-100 ml-2">
                      <ul class="text-xs text-gray-500 space-y-1">
                        <%= for item <- sale.bundle.bundle_items do %>
                          <li>
                            <span class="font-bold text-gray-700"><%= item.quantity %>x</span>
                            <%= item.product.name %>
                          </li>
                        <% end %>
                      </ul>
                    </div>

                  <% true -> %>
                    <span class="text-red-500 italic">Item desconocido</span>
                <% end %>
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-gray-900 font-bold">
                <%= sale.quantity %>
              </td>
              <td class="whitespace-nowrap px-3 py-4 text-sm text-right text-gray-600 font-bold">
                $<%= sale.total_price %>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end
end
