defmodule EzyHomeApp.Repo.Migrations.AddCompanyIdToAllTables do
  use Ecto.Migration

  def change do
    # 1. Actualizar Productos
    alter table(:products) do
      add :company_id, references(:companies, on_delete: :delete_all), null: false
    end
    create index(:products, [:company_id])

    # 2. Actualizar Packs (Bundles)
    alter table(:bundles) do
      add :company_id, references(:companies, on_delete: :delete_all), null: false
    end
    create index(:bundles, [:company_id])

    # 3. Actualizar Ventas (Sales)
    alter table(:sales) do
      add :company_id, references(:companies, on_delete: :delete_all), null: false
    end
    create index(:sales, [:company_id])

    # (Opcional) Si tienes Customers, también deberían ir aquí, pero empecemos con esto.
  end
end
