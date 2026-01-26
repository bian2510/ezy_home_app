defmodule EzyHomeApp.Inventory.Products do
  @moduledoc """
  Bussiness Logic for individual products.
  """
  import Ecto.Query, warn: false
  alias EzyHomeApp.Repo
  alias EzyHomeApp.Inventory.Schemas.Product

  def list(company_id) do
    Product
    |> where(company_id: ^company_id)
    |> order_by([asc: :id])
    |> Repo.all()
  end

  def get!(company_id, id), do: Repo.get!(Product, id: id, company_id: company_id)

  def create(company_id, attrs \\ %{}) do
    %Product{company_id: company_id}
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

  def search(company_id, query) do
    search_term = "%#{query}%"

    Product
    |> where(company_id: ^company_id)
    |> where([p], ilike(p.name, ^search_term) or ilike(p.sku, ^search_term))
    |> limit(5)
    |> Repo.all()
  end

  def sell_product(company_id, id, quantity \\ 1) do
    # 1. Buscamos el producto (nos aseguramos de tener el struct completo)
    product = Repo.get!(Product, id: id, company_id: company_id)

    if product.current_stock >= quantity do
      # 2. Calculamos el nuevo stock
      new_stock = product.current_stock - quantity

      # 3. Preparamos el cambio y guardamos
      # Usamos Ecto.Changeset.change para cambiar solo ese campo sin validar el resto
      product
      |> Ecto.Changeset.change(current_stock: new_stock)
      |> Repo.update()
    else
      {:error, "Stock insuficiente (Tienes #{product.current_stock}, intentas vender #{quantity})."}
    end
  end

  def list_low_stock_products(company_id) do
    Product
    |> where(company_id: ^company_id)
    |> where([p], p.current_stock <= p.min_stock_threshold)
    |> Repo.all()
  end
end
