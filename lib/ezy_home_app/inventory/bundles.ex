defmodule EzyHomeApp.Inventory.Bundles do
  @moduledoc """
  Advanced Business Logic for Bundles and virtual stock calculation.
  """
  import Ecto.Query, warn: false
  alias EzyHomeApp.Repo
  alias EzyHomeApp.Inventory.Schemas.{Bundle, BundleItem}

  def list do
    Repo.all(Bundle)
  end

  def get!(id), do: Repo.get!(Bundle, id)

  def create(attrs \\ %{}) do
    %Bundle{}
    |> Bundle.changeset(attrs)
    |> Repo.insert()
  end

  def create_item(attrs \\ %{}) do
    %BundleItem{}
    |> BundleItem.changeset(attrs)
    |> Repo.insert()
  end

  # 1. Función interna para calcular stock de un solo pack
  def calculate_stock(%Bundle{} = bundle) do
    bundle = Repo.preload(bundle, bundle_items: :product)

    if Enum.empty?(bundle.bundle_items) do
      0
    else
      possible_quantities =
        Enum.map(bundle.bundle_items, fn item ->
          if item.quantity > 0 do
            div(item.product.current_stock, item.quantity)
          else
            0
          end
        end)

      Enum.min(possible_quantities)
    end
  end

  def list_with_virtual_stock do
    list()
    |> Repo.preload(bundle_items: :product)
    |> Enum.map(fn bundle ->
      Map.put(bundle, :virtual_stock, calculate_stock(bundle))
    end)
  end

  def sell(bundle_id, quantity_sold) do
    Repo.transaction(fn ->
      bundle = Repo.get!(Bundle, bundle_id) |> Repo.preload(bundle_items: :product)

      Enum.each(bundle.bundle_items, fn item ->
        product = item.product
        total_to_remove = item.quantity * quantity_sold

        if product.current_stock < total_to_remove do
          Repo.rollback("Stock insuficiente del producto: #{product.name}")
        else
          product
          |> Ecto.Changeset.change(current_stock: product.current_stock - total_to_remove)
          |> Repo.update!()
        end
      end)
      bundle
    end)
  end
end
