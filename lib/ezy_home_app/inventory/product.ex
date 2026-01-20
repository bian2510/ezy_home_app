defmodule EzyHomeApp.Inventory.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :sku, :string
    field :current_stock, :integer
    field :min_stock, :integer
    field :mercadolibre_id, :string

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :sku, :current_stock, :min_stock, :mercadolibre_id])
    |> validate_required([:name, :sku, :current_stock, :min_stock, :mercadolibre_id])
  end
end
