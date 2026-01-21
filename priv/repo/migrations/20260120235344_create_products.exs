defmodule EzyHomeApp.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string, null: false
      add :sku, :string, null: false
      add :description, :text
      add :current_stock, :integer, default: 0, null: false
      add :min_stock_threshold, :integer, default: 5, null: false
      add :mercadolibre_id, :string
      add :price, :decimal, precision: 10, scale: 2

      timestamps()
    end

    create unique_index(:products, [:sku])
    create index(:products, [:mercadolibre_id])
  end
end
