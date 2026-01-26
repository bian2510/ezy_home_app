defmodule EzyHomeApp.Sales.Sale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sales" do
    field :quantity, :integer
    field :total_price, :decimal

    # Relaciones
    belongs_to :user, EzyHomeApp.Accounts.User
    belongs_to :product, EzyHomeApp.Inventory.Schemas.Product
    belongs_to :bundle, EzyHomeApp.Inventory.Schemas.Bundle
    belongs_to :company, EzyHomeApp.Accounts.Company

    timestamps(type: :utc_datetime)
  end

  def changeset(sale, attrs) do
    sale
    |> cast(attrs, [:quantity, :total_price, :user_id, :product_id, :bundle_id, :company_id])
    |> validate_required([:quantity, :total_price, :user_id, :company_id])
    |> validate_product_or_bundle()
  end

  defp validate_product_or_bundle(changeset) do
    if get_field(changeset, :product_id) || get_field(changeset, :bundle_id) do
      changeset
    else
      add_error(changeset, :base, "La venta debe incluir un producto o un pack")
    end
  end
end
