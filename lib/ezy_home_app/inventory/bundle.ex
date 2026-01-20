defmodule EzyHomeApp.Inventory.Bundle do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bundles" do
    field :name, :string
    field :sku, :string
    field :mercadolibre_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bundle, attrs) do
    bundle
    |> cast(attrs, [:name, :sku, :mercadolibre_id])
    |> validate_required([:name, :sku, :mercadolibre_id])
  end
end
