defmodule EzyHomeAppWeb.DashboardLiveTest do
  use EzyHomeAppWeb.ConnCase
  import Phoenix.LiveViewTest
  import EzyHomeApp.AccountsFixtures
  # Necesitamos alias para crear datos directo en la BD
  alias EzyHomeApp.Repo
  alias EzyHomeApp.Sales.Sale
  import EzyHomeApp.InventoryFixtures

  describe "Dashboard" do
    test "usuario logueado ve el panel de control y estadísticas", %{conn: conn} do
      # 1. Preparar datos
      user = user_fixture()
      product = product_fixture(%{name: "Producto Test", price: 100})

      # Insertar una venta manual para que aparezca en "Últimas Ventas"
      Repo.insert!(%Sale{
        user_id: user.id,
        product_id: product.id,
        quantity: 1,
        total_price: Decimal.new("100.00"),
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      # 2. Loguearse y entrar al Dashboard (que ahora es "/")
      {:ok, _lv, html} =
        conn
        |> log_in_user(user)
        |> live(~p"/")

      # 3. Verificaciones visuales
      assert html =~ "Panel de Control" # Título
      assert html =~ "Ventas de Hoy"    # Tarjeta KPI
      assert html =~ "$100"             # El monto de la venta
      assert html =~ "Producto Test"    # En la lista de últimas ventas
    end

    test "usuario NO logueado es redirigido", %{conn: conn} do
      # Intentar entrar sin login
      conn = get(conn, ~p"/")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end
end
