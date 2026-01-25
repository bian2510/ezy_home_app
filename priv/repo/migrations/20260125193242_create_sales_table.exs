defmodule EzyHomeApp.Repo.Migrations.CreateSalesTable do
  use Ecto.Migration

  def change do
    create table(:sales) do
      # ¿Quién vendió?
      add :user_id, references(:users, on_delete: :nothing)

      # ¿Qué vendió? (Puede ser Producto O Pack, por eso permitimos nulos)
      add :product_id, references(:products, on_delete: :nothing), null: true
      add :bundle_id, references(:bundles, on_delete: :nothing), null: true

      # Detalles de la venta
      add :quantity, :integer, null: false
      add :total_price, :decimal, null: false

      timestamps(type: :utc_datetime)
    end

    # Índices para que las búsquedas sean rápidas
    create index(:sales, [:user_id])
    create index(:sales, [:product_id])
    create index(:sales, [:bundle_id])
  end
end
