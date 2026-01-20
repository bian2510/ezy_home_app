defmodule EzyHomeApp.Inventory.BundleItem do
  use Ecto.Schema
  import Ecto.Changeset

  schema "bundle_items" do
    field :quantity, :integer

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(bundle_item, attrs) do
    bundle_item
    |> cast(attrs, [:quantity])
    |> validate_required([:quantity])
  end
end
