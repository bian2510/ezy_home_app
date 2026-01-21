defmodule EzyHomeApp.Inventory.Product do
  use Ecto.Schema
  import Ecto.Changeset

  schema "products" do
    field :name, :string
    field :sku, :string
    field :description, :string
    field :current_stock, :integer, default: 0
    field :min_stock_threshold, :integer, default: 5
    field :mercadolibre_id, :string
    field :price, :decimal

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :sku, :description, :current_stock, :min_stock_threshold, :mercadolibre_id, :price])
    |> validate_required([:name, :sku, :current_stock])
    |> validate_number(:current_stock, greater_than_or_equal_to: 0)
    |> unique_constraint(:sku)
  end
end
