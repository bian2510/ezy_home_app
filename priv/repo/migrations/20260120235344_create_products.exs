defmodule EzyHomeApp.Repo.Migrations.CreateProducts do
  use Ecto.Migration

  def change do
    create table(:products) do
      add :name, :string
      add :sku, :string
      add :current_stock, :integer
      add :min_stock, :integer
      add :mercadolibre_id, :string

      timestamps(type: :utc_datetime)
    end
  end
end
