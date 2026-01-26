defmodule EzyHomeApp.SalesTest do
  use EzyHomeApp.DataCase

  alias EzyHomeApp.Sales
  alias EzyHomeApp.Sales.Sale
  import EzyHomeApp.AccountsFixtures
  import EzyHomeApp.InventoryFixtures

  describe "estadísticas de ventas" do
    test "get_today_stats/0 calcula solo las ventas de hoy (UTC)" do
      user = user_fixture()
      product = product_fixture(%{price: Decimal.new("10.00")})

      # Venta 1: HOY ($10)
      Repo.insert!(%Sale{
        user_id: user.id,
        product_id: product.id,
        quantity: 1,
        total_price: Decimal.new("10.00"),
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      # Venta 2: HOY ($20)
      Repo.insert!(%Sale{
        user_id: user.id,
        product_id: product.id,
        quantity: 2,
        total_price: Decimal.new("20.00"),
        inserted_at: DateTime.utc_now() |> DateTime.truncate(:second)
      })

      # Venta 3: AYER ($50) - Esta NO debe sumarse
      yesterday = DateTime.utc_now() |> DateTime.add(-24, :hour) |> DateTime.truncate(:second)
      Repo.insert!(%Sale{
        user_id: user.id,
        product_id: product.id,
        quantity: 5,
        total_price: Decimal.new("50.00"),
        inserted_at: yesterday
      })

      # Ejecutar
      stats = Sales.get_today_stats()

      # Verificar
      # Total esperado: 10 + 20 = 30 (La de 50 se ignora)
      assert stats.count == 2
      assert Decimal.eq?(stats.total, Decimal.new("30.00"))
    end
  end
end
