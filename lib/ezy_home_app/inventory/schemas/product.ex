defmodule EzyHomeApp.Inventory.Schemas.Product do
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

    belongs_to :company, EzyHomeApp.Accounts.Company

    timestamps()
  end

  @doc false
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :sku, :description, :current_stock, :min_stock_threshold, :mercadolibre_id, :price, :company_id])
    |> validate_required([:name, :sku, :price, :current_stock, :company_id])
    |> validate_number(:current_stock, greater_than_or_equal_to: 0)
    |> unique_constraint([:sku, :company_id], message: "Este SKU ya existe en tu inventario")
  end
end
