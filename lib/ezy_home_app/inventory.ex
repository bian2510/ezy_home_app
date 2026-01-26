defmodule EzyHomeApp.Inventory do
  @moduledoc """
  Fachada del Inventario.
  Este archivo es el único con el que hablará tu página web (LiveView).
  """

  # Llamamos a los módulos que creamos hace un momento
  alias EzyHomeApp.Inventory.Products
  alias EzyHomeApp.Inventory.Bundles

  # =================================================================
  # DELEGACIONES: Si piden "x", que lo haga el módulo correspondiente
  # =================================================================

  # --- PRODUCTOS ---
  defdelegate list_products, to: Products, as: :list
  defdelegate get_product!(id), to: Products, as: :get!
  defdelegate create_product(attrs), to: Products, as: :create
  defdelegate update_product(product, attrs), to: Products, as: :update
  defdelegate delete_product(product), to: Products, as: :delete
  defdelegate sell_product(id, quantity \\ 1), to: Products, as: :sell_product
  defdelegate list_low_stock_products, to: Products, as: :list_low_stock_products

  defdelegate search_products(query), to: Products, as: :search

  # --- PACKS (BUNDLES) ---
  defdelegate list_bundles, to: Bundles, as: :list
  defdelegate get_bundle!(id), to: Bundles, as: :get!
  defdelegate create_bundle(attrs), to: Bundles, as: :create
  defdelegate create_bundle_item(attrs), to: Bundles, as: :create_item
  defdelegate add_item_to_bundle(bundle_id, product_id), to: Bundles, as: :add_item
  defdelegate dec_item_quantity(item_id), to: Bundles, as: :dec_item_quantity
  defdelegate remove_item_from_bundle(item_id), to: Bundles, as: :remove_item


  # --- FUNCIONES ESPECIALES (Stock Virtual) ---
  defdelegate calculate_bundle_stock(bundle), to: Bundles, as: :calculate_stock
  defdelegate list_bundles_with_stock, to: Bundles, as: :list_with_virtual_stock
  defdelegate sell_bundle(id, quantity \\ 1), to: Bundles, as: :sell
end
