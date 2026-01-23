defmodule EzyHomeApp.Inventory.BundlesLogicTest do
  use EzyHomeApp.DataCase

  alias EzyHomeApp.Inventory

  describe "logica de packs" do
    # Antes de cada test, preparamos el terreno
    setup do
      # Creamos 2 productos
      {:ok, teclado} = Inventory.create_product(%{name: "Teclado", sku: "KEY-001", price: 100, current_stock: 10})
      {:ok, mouse} = Inventory.create_product(%{name: "Mouse", sku: "MOU-001", price: 50, current_stock: 4}) # <--- LIMITANTE

      # Creamos el pack vacio
      {:ok, bundle} = Inventory.create_bundle(%{name: "Pack Gamer", sku: "PACK-001", price: 120})

      %{teclado: teclado, mouse: mouse, bundle: bundle}
    end

    test "agregar un item repetido suma cantidad en vez de dar error", %{bundle: bundle, mouse: mouse} do
      # 1. Agregamos el mouse por primera vez
      assert {:ok, item1} = Inventory.add_item_to_bundle(bundle.id, mouse.id)
      assert item1.quantity == 1

      # 2. Agregamos EL MISMO mouse otra vez
      assert {:ok, item2} = Inventory.add_item_to_bundle(bundle.id, mouse.id)

      # 3. Verificamos que ahora la cantidad sea 2
      assert item2.quantity == 2
    end

    test "calcula el stock virtual correctamente (cuello de botella)", %{bundle: bundle, teclado: teclado, mouse: mouse} do
      # Pack lleva: 1 Teclado y 1 Mouse
      Inventory.add_item_to_bundle(bundle.id, teclado.id)
      Inventory.add_item_to_bundle(bundle.id, mouse.id)

      # Recargamos el bundle
      bundle = Inventory.get_bundle!(bundle.id)

      # Teclado hay 10, Mouse hay 4. El stock del pack debe ser 4.
      assert Inventory.calculate_bundle_stock(bundle) == 4
    end

    test "calcula stock virtual con cantidades mayores", %{bundle: bundle, mouse: mouse} do
      # Digamos que el pack lleva 2 Mouses
      Inventory.add_item_to_bundle(bundle.id, mouse.id)
      Inventory.add_item_to_bundle(bundle.id, mouse.id) # Ahora cantidad es 2

      # Recargamos
      bundle = Inventory.get_bundle!(bundle.id)

      # Si tengo 4 mouses físicos y el pack usa 2... puedo armar 2 packs.
      assert Inventory.calculate_bundle_stock(bundle) == 2
    end

    test "vender un pack descuenta el stock fisico de los ingredientes", %{bundle: bundle, teclado: teclado, mouse: mouse} do
      # Preparamos: Pack lleva 1 Teclado y 1 Mouse
      Inventory.add_item_to_bundle(bundle.id, teclado.id)
      Inventory.add_item_to_bundle(bundle.id, mouse.id)

      # Stock inicial: Teclado=10, Mouse=4

      # ACCIÓN: Vendemos 1 Pack
      assert {:ok, _} = Inventory.sell_bundle(bundle.id)

      # VERIFICACIÓN:
      teclado_actualizado = Inventory.get_product!(teclado.id)
      mouse_actualizado = Inventory.get_product!(mouse.id)

      assert teclado_actualizado.current_stock == 9  # Bajó 1
      assert mouse_actualizado.current_stock == 3    # Bajó 1
    end
  end
end
