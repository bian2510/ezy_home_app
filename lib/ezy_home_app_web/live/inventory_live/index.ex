defmodule EzyHomeAppWeb.InventoryLive.Index do
  use EzyHomeAppWeb, :live_view

  # Importamos nuestra fachada limpia
  alias EzyHomeApp.Inventory

  @impl true
  def mount(_params, _session, socket) do
    # 1. Cargamos productos físicos
    products = Inventory.list_products()

    # 2. Cargamos packs (¡Con el cálculo matemático incluido!)
    bundles = Inventory.list_bundles_with_stock()

    {:ok, assign(socket, products: products, bundles: bundles)}
  end

  # Aquí manejaremos eventos futuros (clics, actualizaciones, etc.)
end
