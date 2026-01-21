defmodule EzyHomeApp.InventoryFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EzyHomeApp.Inventory` context.
  """

  alias EzyHomeApp.Inventory

  def unique_product_sku, do: "SKU#{System.unique_integer([:positive])}"
  def unique_bundle_sku, do: "PACK#{System.unique_integer([:positive])}"

  def product_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        name: "Producto Test",
        sku: unique_product_sku(),
        current_stock: 10,
        min_stock_threshold: 5,
        price: "120.50"
      })

    {:ok, product} = Inventory.create_product(attrs)
    product
  end

  def bundle_fixture(attrs \\ %{}) do
    attrs =
      attrs
      |> Enum.into(%{
        name: "Pack Test",
        sku: unique_bundle_sku(),
        active: true,
        description: "Un pack de prueba"
      })

    {:ok, bundle} = Inventory.create_bundle(attrs)
    bundle
  end
end
