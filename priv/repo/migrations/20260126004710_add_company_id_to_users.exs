defmodule EzyHomeApp.Repo.Migrations.AddCompanyIdToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      # Agregamos la referencia.
      # on_delete: :delete_all significa que si borras la empresa, se borran sus usuarios.
      add :company_id, references(:companies, on_delete: :delete_all), null: false
    end

    create index(:users, [:company_id])
  end
end
