defmodule EzyHomeApp.Inventory.Bundle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bundles" do
    field :name, :string
    field :sku, :string
    field :description, :string
    field :mercadolibre_id, :string
    field :active, :boolean, default: true

    has_many :bundle_items, EzyHomeApp.Inventory.BundleItem

    has_many :products, through: [:bundle_items, :product]

    timestamps()
  end

  def changeset(bundle, attrs) do
    bundle
    |> cast(attrs, [:name, :sku, :description, :mercadolibre_id, :active])
    |> validate_required([:name, :sku])
    |> unique_constraint(:sku)
  end
end
