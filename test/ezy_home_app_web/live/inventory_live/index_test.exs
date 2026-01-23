defmodule EzyHomeAppWeb.InventoryLive.IndexTest do
  use EzyHomeAppWeb.ConnCase

  import Phoenix.LiveViewTest
  alias EzyHomeApp.Inventory

  describe "Index de Inventario (Packs)" do
    setup do
      # 1. Creamos Ingredientes (30 tornillos)
      {:ok, prod_a} = Inventory.create_product(%{name: "Tornillo", sku: "TOR-1", price: 1, current_stock: 30})

      # 2. Creamos un Pack
      {:ok, bundle} = Inventory.create_bundle(%{name: "Pack Constructor", sku: "PK-CONST", price: 50})

      # 3. Agregamos el item al pack (se crea con cantidad: 1)
      {:ok, item} = Inventory.add_item_to_bundle(bundle.id, prod_a.id)

      # 4. Actualizamos MANUALMENTE la cantidad a 10 para el test
      # (30 tornillos / 10 requeridos = 3 packs posibles)
      EzyHomeApp.Repo.get!(EzyHomeApp.Inventory.Schemas.BundleItem, item.id)
      |> Ecto.Changeset.change(quantity: 10)
      |> EzyHomeApp.Repo.update!()

      %{bundle: bundle}
    end

    test "lista los packs y muestra el stock virtual calculado", %{conn: conn, bundle: bundle} do
      # 1. Entrar a la página principal
      {:ok, view, _html} = live(conn, ~p"/inventory")

      # 2. Verificar que el título del pack existe
      assert has_element?(view, "td", bundle.name)

      # 3. Verificar el SKU
      assert has_element?(view, "td", bundle.sku)

      # 4. LA PRUEBA DE FUEGO: Verificar el Stock Virtual
      # El sistema debe haber calculado 30 / 10 = 3
      # Buscamos un elemento que contenga "3 u." (que es como lo pusimos en el HTML)
      assert has_element?(view, "span", "3 Packs")
    end

    test "tiene un link para ir al detalle del pack", %{conn: conn, bundle: bundle} do
      {:ok, view, _html} = live(conn, ~p"/inventory")

      # Buscamos el enlace. verify que el href apunte a /inventory/bundles/:id
      assert has_element?(view, "a[href='/inventory/bundles/#{bundle.id}']", bundle.name)
    end
  end
end
