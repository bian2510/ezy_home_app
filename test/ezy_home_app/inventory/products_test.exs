defmodule EzyHomeApp.Inventory.ProductsTest do
  use EzyHomeApp.DataCase

  alias EzyHomeApp.Inventory
  alias EzyHomeApp.Repo
  alias EzyHomeApp.Inventory.Schemas.Product

  describe "Packs y Stock Virtual" do
    # Configuramos los datos antes de cada test
    setup do
      # Creamos 2 productos
      # Producto A: Tenemos 10 unidades
      {:ok, prod_a} = Inventory.create_product(%{name: "Hub", sku: "HUB-01", current_stock: 10, min_stock_threshold: 2})

      # Producto B: Tenemos 50 unidades
      {:ok, prod_b} = Inventory.create_product(%{name: "Sensor", sku: "SENS-01", current_stock: 50, min_stock_threshold: 5})

      # Creamos el Pack
      {:ok, bundle} = Inventory.create_bundle(%{name: "Kit Inicio", sku: "KIT-01", active: true})

      {:ok, %{prod_a: prod_a, prod_b: prod_b, bundle: bundle}}
    end

    test "calculate_bundle_stock/1 calcula el stock basado en el componente limitante", %{prod_a: prod_a, prod_b: prod_b, bundle: bundle} do
      # Escenario: El pack lleva 1 Hub y 2 Sensores.
      # Hubs disponibles para packs: 10 / 1 = 10 packs.
      # Sensores disponibles para packs: 50 / 2 = 25 packs.
      # El stock del pack DEBERÍA ser 10 (el menor).

      Inventory.create_bundle_item(%{bundle_id: bundle.id, product_id: prod_a.id, quantity: 1})
      Inventory.create_bundle_item(%{bundle_id: bundle.id, product_id: prod_b.id, quantity: 2})

      stock_virtual = Inventory.calculate_bundle_stock(bundle)

      assert stock_virtual == 10
    end

    test "sell_bundle/2 descuenta stock de los productos hijos", %{prod_a: prod_a, prod_b: prod_b, bundle: bundle} do
      # Configuración igual al anterior
      Inventory.create_bundle_item(%{bundle_id: bundle.id, product_id: prod_a.id, quantity: 1})
      Inventory.create_bundle_item(%{bundle_id: bundle.id, product_id: prod_b.id, quantity: 2})

      # Acción: Vendemos 1 pack
      {:ok, _result} = Inventory.sell_bundle(bundle.id, 1)

      # Verificación: Recargamos los productos de la DB para ver sus nuevos valores
      prod_a_updated = Repo.get!(Product, prod_a.id)
      prod_b_updated = Repo.get!(Product, prod_b.id)

      # Hub: 10 - 1 = 9
      assert prod_a_updated.current_stock == 9
      # Sensor: 50 - 2 = 48
      assert prod_b_updated.current_stock == 48
    end

    test "sell_bundle/2 falla si no hay suficiente stock físico", %{prod_a: prod_a, bundle: bundle} do
      # Pack con 1 Hub
      Inventory.create_bundle_item(%{bundle_id: bundle.id, product_id: prod_a.id, quantity: 1})

      # Acción: Intentamos vender 20 packs (solo tenemos 10 Hubs)
      assert {:error, "Stock insuficiente del producto: Hub"} = Inventory.sell_bundle(bundle.id, 20)

      # Verificación: El stock no debió cambiar (Rollback de transacción)
      prod_a_updated = Repo.get!(Product, prod_a.id)
      assert prod_a_updated.current_stock == 10
    end
  end
end
