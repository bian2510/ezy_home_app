defmodule EzyHomeApp.Repo.Migrations.AddPriceToBundles do
  use Ecto.Migration

  def change do
    alter table(:bundles) do
      add :price, :decimal, precision: 10, scale: 2, default: 0.0, null: false
    end
  end
end
