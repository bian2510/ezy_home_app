defmodule EzyHomeApp.Repo.Migrations.CreateBundles do
  use Ecto.Migration

  def change do
    create table(:bundles) do
      add :name, :string
      add :sku, :string
      add :mercadolibre_id, :string

      timestamps(type: :utc_datetime)
    end
  end
end
