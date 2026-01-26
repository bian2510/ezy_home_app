defmodule EzyHomeApp.Inventory.Bundles do
  @moduledoc """
  Advanced Business Logic for Bundles and virtual stock calculation.
  """
  import Ecto.Query, warn: false
  alias EzyHomeApp.Repo
  alias EzyHomeApp.Inventory.Schemas.{Bundle, BundleItem}

  def list do
    Repo.all(Bundle)
  end

  def get!(id) do
    Bundle
    |> Repo.get!(id)
    |> Repo.preload(bundle_items: :product)
  end

  def create(attrs \\ %{}) do
    %Bundle{}
    |> Bundle.changeset(attrs)
    |> Repo.insert()
  end

  def create_item(attrs \\ %{}) do
    %BundleItem{}
    |> BundleItem.changeset(attrs)
    |> Repo.insert()
  end

  # 1. Función interna para calcular stock de un solo pack
  def calculate_stock(%Bundle{} = bundle) do
    bundle = Repo.preload(bundle, bundle_items: :product)

    if Enum.empty?(bundle.bundle_items) do
      0
    else
      possible_quantities =
        Enum.map(bundle.bundle_items, fn item ->
          if item.quantity > 0 do
            div(item.product.current_stock, item.quantity)
          else
            0
          end
        end)

      Enum.min(possible_quantities)
    end
  end

  def list_with_virtual_stock do
    list()
    |> Repo.preload(bundle_items: :product)
    |> Enum.map(fn bundle ->
      Map.put(bundle, :virtual_stock, calculate_stock(bundle))
    end)
  end

  def sell(bundle_id, quantity_sold) do
    Repo.transaction(fn ->
      bundle = Repo.get!(Bundle, bundle_id) |> Repo.preload(bundle_items: :product)

      Enum.each(bundle.bundle_items, fn item ->
        product = item.product
        total_to_remove = item.quantity * quantity_sold

        if product.current_stock < total_to_remove do
          Repo.rollback("Stock insuficiente del producto: #{product.name}")
        else
          product
          |> Ecto.Changeset.change(current_stock: product.current_stock - total_to_remove)
          |> Repo.update!()
        end
      end)
      bundle
    end)
  end

  def add_item(bundle_id, product_id) do
    # 1. Preguntamos: ¿Ya existe este producto en este pack?
    case Repo.get_by(BundleItem, bundle_id: bundle_id, product_id: product_id) do
      nil ->
        # NO existe -> Creamos uno nuevo con cantidad 1
        %BundleItem{}
        |> BundleItem.changeset(%{bundle_id: bundle_id, product_id: product_id, quantity: 1})
        |> Repo.insert()

      existing_item ->
        # SÍ existe -> Le sumamos 1 a la cantidad actual
        existing_item
        |> Ecto.Changeset.change(quantity: existing_item.quantity + 1)
        |> Repo.update()
    end
  end

  def dec_item_quantity(item_id) do
    item = Repo.get!(BundleItem, item_id)

    if item.quantity > 1 do
      # Si hay más de 1, restamos
      item
      |> Ecto.Changeset.change(quantity: item.quantity - 1)
      |> Repo.update()
    else
      # Si hay 1 y restamos, ¿lo borramos?
      # Por seguridad, mejor no hacemos nada y dejamos que use el botón "Quitar".
      {:ok, item}
    end
  end

  def remove_item(item_id) do
    BundleItem
    |> Repo.get!(item_id)
    |> Repo.delete()
  end

  def sell_bundle(bundle_id, quantity \\ 1) do
    # 1. Buscamos el pack y sus ingredientes
    bundle = get!(bundle_id)

    # 2. Abrimos una transacción (Todo o Nada)
    Repo.transaction(fn ->
      Enum.each(bundle.bundle_items, fn item ->
        product = item.product
        total_to_remove = item.quantity * quantity
        new_stock = product.current_stock - total_to_remove

        # Verificación de seguridad
        if new_stock < 0 do
          Repo.rollback("No hay suficiente stock de #{product.name}")
        else
          product
          |> Ecto.Changeset.change(current_stock: new_stock)
          |> Repo.update!()
        end
      end)
    end)
  end

  def update_price_from_ingredients(bundle_id) do
    bundle = get!(bundle_id)

    # 1. Calculamos la suma total
    new_price =
      Enum.reduce(bundle.bundle_items, Decimal.new("0.00"), fn item, acc ->
        item_cost = Decimal.mult(item.product.price, Decimal.new(item.quantity))
        Decimal.add(acc, item_cost)
      end)

    # 2. Actualizamos el campo price del Bundle
    bundle
    |> Ecto.Changeset.change(price: new_price)
    |> Repo.update()
  end
end
