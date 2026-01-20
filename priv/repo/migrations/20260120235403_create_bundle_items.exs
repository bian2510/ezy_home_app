defmodule EzyHomeApp.Repo.Migrations.CreateBundleItems do
  use Ecto.Migration

  def change do
    create table(:bundle_items) do
      add :quantity, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
