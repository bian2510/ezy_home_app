defmodule EzyHomeApp.Repo.Migrations.CreateCompanies do
  use Ecto.Migration

  def change do
    create table(:companies) do
      add :name, :string, null: false
      add :tax_id, :string

      timestamps(type: :utc_datetime)
    end

    create index(:companies, [:name])
  end
end
