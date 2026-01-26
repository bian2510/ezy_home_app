defmodule EzyHomeAppWeb.DashboardLive.Index do
  use EzyHomeAppWeb, :live_view
  alias EzyHomeApp.{Sales, Inventory}

  def mount(_params, _session, socket) do
    # 1. Traemos las 3 piezas de información clave
    stats = Sales.get_today_stats()
    low_stock = Inventory.list_low_stock_products()
    recent_sales = Sales.list_recent_sales(5)

    {:ok,
     socket
     |> assign(:page_title, "Dashboard")
     |> assign(:stats, stats)
     |> assign(:low_stock, low_stock)
     |> assign(:recent_sales, recent_sales)}
  end

  def render(assigns) do
    ~H"""
    <div class="px-4 py-6 sm:px-6 lg:px-8 bg-gray-50 min-h-screen">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">🚀 Panel de Control</h1>

      <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 mb-8">
        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0 bg-indigo-500 rounded-md p-3">
                <svg class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">Ventas de Hoy</dt>
                  <dd class="text-3xl font-semibold text-gray-900">$<%= @stats.total %></dd>
                </dl>
              </div>
            </div>
          </div>
        </div>

        <div class="bg-white overflow-hidden shadow rounded-lg">
          <div class="p-5">
            <div class="flex items-center">
              <div class="flex-shrink-0 bg-green-500 rounded-md p-3">
                <svg class="h-6 w-6 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z" />
                </svg>
              </div>
              <div class="ml-5 w-0 flex-1">
                <dl>
                  <dt class="text-sm font-medium text-gray-500 truncate">Transacciones Hoy</dt>
                  <dd class="text-3xl font-semibold text-gray-900"><%= @stats.count %></dd>
                </dl>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 lg:grid-cols-2 gap-8">
        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900 mb-4 flex items-center">
            ⚠️ Alertas de Stock Bajo
            <span class="ml-2 bg-red-100 text-red-800 text-xs font-semibold px-2.5 py-0.5 rounded-full">
              <%= length(@low_stock) %>
            </span>
          </h2>
          <%= if Enum.empty?(@low_stock) do %>
            <p class="text-gray-500 text-sm">Todo el inventario está saludable. ✅</p>
          <% else %>
            <ul class="divide-y divide-gray-200">
              <%= for product <- @low_stock do %>
                <li class="py-3 flex justify-between items-center">
                  <div>
                    <p class="text-sm font-medium text-gray-900"><%= product.name %></p>
                    <p class="text-xs text-gray-500">SKU: <%= product.sku %></p>
                  </div>
                  <div class="text-right">
                    <span class="text-red-600 font-bold text-sm"><%= product.current_stock %> u.</span>
                    <p class="text-xs text-gray-400">Min: <%= product.min_stock_threshold %></p>
                  </div>
                </li>
              <% end %>
            </ul>
          <% end %>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-lg font-medium text-gray-900 mb-4">⏱️ Últimas Ventas</h2>
          <ul class="divide-y divide-gray-200">
            <%= for sale <- @recent_sales do %>
              <li class="py-3">
                <div class="flex justify-between">
                  <div class="text-sm font-medium text-gray-900">
                    <%= if sale.product, do: "📦 #{sale.product.name}", else: "🎁 #{sale.bundle.name}" %>
                  </div>
                  <div class="text-sm text-green-600 font-bold">+$<%= sale.total_price %></div>
                </div>
                <div class="flex justify-between mt-1">
                  <div class="text-xs text-gray-500">
                    <%= Calendar.strftime(sale.inserted_at, "%H:%M") %> - <%= sale.user.email %>
                  </div>
                  <div class="text-xs text-gray-500">Cant: <%= sale.quantity %></div>
                </div>
              </li>
            <% end %>
          </ul>
           <div class="mt-4 text-center">
            <a href="/sales" class="text-sm text-indigo-600 hover:text-indigo-900 font-medium">Ver todo el historial &rarr;</a>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
