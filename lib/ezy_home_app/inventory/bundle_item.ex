defmodule EzyHomeApp.Inventory.BundleItem do
use Ecto.Schema
  import Ecto.Changeset

  schema "bundle_items" do
    field :quantity, :integer, default: 1

    belongs_to :bundle, EzyHomeApp.Inventory.Bundle
    belongs_to :product, EzyHomeApp.Inventory.Product

    timestamps()
  end

  def changeset(bundle_item, attrs) do
    bundle_item
    |> cast(attrs, [:quantity, :bundle_id, :product_id])
    |> validate_required([:quantity, :bundle_id, :product_id])
    |> validate_number(:quantity, greater_than: 0)
    |> unique_constraint([:bundle_id, :product_id])
  end
end
