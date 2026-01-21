defmodule EzyHomeApp.Repo.Migrations.CreateBundleItems do
  use Ecto.Migration

  def change do
    create table(:bundle_items) do
      add :quantity, :integer, default: 1, null: false
      add :bundle_id, references(:bundles, on_delete: :delete_all), null: false
      add :product_id, references(:products, on_delete: :restrict), null: false

      timestamps()
    end

    create unique_index(:bundle_items, [:bundle_id, :product_id])
  end
end
