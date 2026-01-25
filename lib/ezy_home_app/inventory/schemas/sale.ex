defmodule EzyHomeApp.Inventory.Schemas.Sale do
  use Ecto.Schema
  import Ecto.Changeset

  schema "sales" do
    field :quantity, :integer
    field :total_price, :decimal

    # Relaciones
    belongs_to :user, EzyHomeApp.Accounts.User
    belongs_to :product, EzyHomeApp.Inventory.Schemas.Product
    belongs_to :bundle, EzyHomeApp.Inventory.Schemas.Bundle

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(sale, attrs) do
    sale
    |> cast(attrs, [:quantity, :total_price, :user_id, :product_id, :bundle_id])
    |> validate_required([:quantity, :total_price, :user_id])
    # Validamos que tenga al menos UN producto O un pack
    |> validate_product_or_bundle()
  end

  # Validación personalizada: No puedes vender "nada"
  defp validate_product_or_bundle(changeset) do
    product_id = get_field(changeset, :product_id)
    bundle_id = get_field(changeset, :bundle_id)

    if product_id || bundle_id do
      changeset
    else
      add_error(changeset, :base, "La venta debe incluir un producto o un pack")
    end
  end
end
