defmodule EzyHomeApp.Inventory.Schemas.Bundle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bundles" do
    field :name, :string
    field :sku, :string
    field :description, :string
    field :mercadolibre_id, :string
    field :active, :boolean, default: true
    field :price, :decimal

    has_many :bundle_items, EzyHomeApp.Inventory.Schemas.BundleItem
    has_many :products, through: [:bundle_items, :product]

    timestamps()
  end

  def changeset(bundle, attrs) do
    bundle
    |> cast(attrs, [:name, :sku, :description, :mercadolibre_id, :active, :price])
    |> validate_required([:name, :sku])
    |> unique_constraint(:sku)
  end
end
