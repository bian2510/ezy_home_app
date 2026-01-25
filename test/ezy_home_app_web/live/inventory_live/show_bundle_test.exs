defmodule EzyHomeAppWeb.InventoryLive.ShowBundleTest do
  use EzyHomeAppWeb.ConnCase

  import Phoenix.LiveViewTest
  import EzyHomeApp.AccountsFixtures
  alias EzyHomeApp.Inventory

  setup %{conn: conn} do
    # Preparamos datos: 1 Producto y 1 Pack
    user = user_fixture()
    conn = log_in_user(conn, user) # <--- Logueamos al usuario
    {:ok, product} = Inventory.create_product(%{name: "HDMI Cable", sku: "HDMI-1", price: 10, current_stock: 50})
    {:ok, bundle} = Inventory.create_bundle(%{name: "Pack TV", sku: "PK-TV", price: 100})

    %{conn: conn, bundle: bundle, product: product}
  end

  test "el usuario puede buscar y agregar productos", %{conn: conn, bundle: bundle, product: product} do
    # 1. Entrar a la página del pack
    {:ok, view, _html} = live(conn, ~p"/inventory/bundles/#{bundle}")

    # 2. Verificar que el pack está vacío al principio
    assert has_element?(view, "h1", bundle.name)
    refute has_element?(view, "p", product.name) # No debería estar en la lista todavía

    # 3. Escribir en el buscador (simulamos el evento "search")
    # Buscamos el input por el placeholder o clase, y mandamos el evento keyup
    view
    |> element("input[type=text]")
    |> render_keyup(%{"value" => "HDMI"})

    # 4. Esperar que aparezca en los resultados de búsqueda (lado derecho)
    # Buscamos un botón que contenga el SVG de agregar dentro de la lista de resultados
    assert has_element?(view, "button[phx-click='add_item']")

    # 5. Hacer Click en Agregar (+)
    view
    |> element("button[phx-value-product-id='#{product.id}']")
    |> render_click()

    # 6. Verificar que ahora SI está en la lista de ingredientes (lado izquierdo)
    assert has_element?(view, "p", product.name)
  end
end
