defmodule EzyHomeAppWeb.InventoryLive.IndexTest do
  use EzyHomeAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import EzyHomeApp.InventoryFixtures
  import EzyHomeApp.AccountsFixtures

  # Alias necesarios para insertar datos manualmente
  alias EzyHomeApp.Repo
  alias EzyHomeApp.Inventory.Schemas.BundleItem

  describe "Index de Inventario" do
    setup %{conn: conn} do
      # 1. Crear y Loguear Usuario
      user = user_fixture()
      conn = log_in_user(conn, user)

      # 2. Crear Producto (Forzamos stock a 30 para facilitar la matemática)
      product = product_fixture(%{
        name: "Tornillo",
        sku: "TOR-TEST",
        current_stock: 30,
        price: 10
      })

      # 3. Crear Pack
      bundle = bundle_fixture(%{
        name: "Pack Constructor",
        sku: "PK-TEST"
      })

      %{conn: conn, user: user, product: product, bundle: bundle}
    end

    test "lista los packs y productos", %{conn: conn, bundle: bundle, product: product} do
      {:ok, _view, html} = live(conn, ~p"/inventory")

      assert html =~ bundle.name
      assert html =~ product.name
    end

    test "el usuario puede vender un PRODUCTO desde el modal", %{conn: conn, product: product} do
      {:ok, index_live, _html} = live(conn, ~p"/inventory")

      # 1. Abrir Modal (buscando por ID del producto)
      index_live
      |> element("button[phx-click='open_sell_modal'][phx-value-id='#{product.id}']")
      |> render_click()

      # 2. Llenar formulario (Vender 5) y Enviar
      index_live
      |> form("#sell-modal form", %{"quantity" => "5"})
      |> render_submit()

      # 3. VALIDACIÓN MATEMÁTICA
      # Teníamos 30. Vendimos 5. Debe quedar 25.
      # Buscamos que el número "25" aparezca en el HTML renderizado.
      assert render(index_live) =~ "25"
    end

    test "el usuario puede vender un PACK y se actualiza el stock", %{conn: conn, bundle: bundle, product: product} do
      # --- SETUP MANUAL: Crear la relación Pack-Producto ---
      # Como no tenemos fixture para esto, lo insertamos directo en la DB
      %BundleItem{}
      |> Ecto.Changeset.change(%{
        bundle_id: bundle.id,
        product_id: product.id,
        quantity: 1
      })
      |> Repo.insert!()
      # -----------------------------------------------------

      {:ok, index_live, _html} = live(conn, ~p"/inventory")

      # 1. Abrir Modal de Pack
      index_live
      |> element("button[phx-click='open_sell_bundle_modal'][phx-value-id='#{bundle.id}']")
      |> render_click()

      # 2. Vender 2 Packs
      index_live
      |> form("#sell-bundle-modal form", %{"quantity" => "2"})
      |> render_submit()

      # 3. VALIDACIÓN MATEMÁTICA
      # Teníamos 30 productos.
      # Vendimos 2 Packs. Cada pack usa 1 producto. Total descontado: 2.
      # 30 - 2 = 28.
      # Verificamos que el número "28" aparezca en la pantalla.
      assert render(index_live) =~ "28"
    end
  end
end
