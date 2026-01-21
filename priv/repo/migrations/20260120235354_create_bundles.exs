defmodule EzyHomeApp.Repo.Migrations.CreateBundles do
  use Ecto.Migration

  def change do
create table(:bundles) do
      add :name, :string, null: false
      add :sku, :string, null: false
      add :description, :text
      add :mercadolibre_id, :string
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:bundles, [:sku])
  end
end
