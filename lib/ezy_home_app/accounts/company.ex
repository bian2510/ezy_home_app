defmodule EzyHomeApp.Accounts.Company do
  use Ecto.Schema
  import Ecto.Changeset

  schema "companies" do
    field :name, :string
    field :tax_id, :string

    has_many :users, EzyHomeApp.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(company, attrs) do
    company
    |> cast(attrs, [:name, :tax_id])
    |> validate_required([:name, :tax_id])
    |> unique_constraint(:name)
  end
end
