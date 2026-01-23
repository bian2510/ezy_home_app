defmodule EzyHomeApp.Inventory.Products do
  @moduledoc """
  Bussiness Logic for individual products.
  """
  import Ecto.Query, warn: false
  alias EzyHomeApp.Repo
  alias EzyHomeApp.Inventory.Schemas.Product

  def list do
    Product
    |> order_by([asc: :id])
    |> Repo.all()
  end

  def get!(id), do: Repo.get!(Product, id)

  def create(attrs \\ %{}) do
    %Product{}
    |> Product.changeset(attrs)
    |> Repo.insert()
  end

  def update(%Product{} = product, attrs) do
    product
    |> Product.changeset(attrs)
    |> Repo.update()
  end

  def delete(%Product{} = product) do
    Repo.delete(product)
  end
end
