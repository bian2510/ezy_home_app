defmodule EzyHomeApp.Sales do
  @moduledoc """
  Contexto para manejar la lógica de ventas.
  """
  import Ecto.Query, warn: false
  alias EzyHomeApp.Repo
  alias EzyHomeApp.Sales.Sale
  alias EzyHomeApp.Inventory # Necesitamos llamar a Inventory para descontar stock

  # --- CREAR VENTA (Transacción que une Stock + Recibo) ---

  def record_sale(user, type, item_id, quantity) do
    Repo.transaction(fn ->
      # 1. Descontamos Stock (Delegamos esta responsabilidad a Inventory)
      case decrease_stock(type, item_id, quantity) do
        {:ok, item} ->
          # 2. Si hay stock, calculamos precio y guardamos la venta
          price = item.price
          total = Decimal.mult(price, Decimal.new(quantity))

          create_sale_record!(user, type, item.id, quantity, total)

        {:error, msg} ->
          # Si falla el stock, cancelamos todo
          Repo.rollback(msg)
      end
    end)
  end

  # --- Funciones Privadas de ayuda ---

  # Paso 1: Llamar a la función correcta de Inventory
  defp decrease_stock(:product, id, qty), do: Inventory.sell_product(id, qty)
  defp decrease_stock(:bundle, id, qty), do: Inventory.sell_bundle(id, qty)

  # Paso 2: Insertar en la tabla sales
  defp create_sale_record!(user, :product, product_id, qty, total) do
    %Sale{}
    |> Sale.changeset(%{
      user_id: user.id,
      product_id: product_id,
      quantity: qty,
      total_price: total
    })
    |> Repo.insert!()
  end

  defp create_sale_record!(user, :bundle, bundle_id, qty, total) do
    %Sale{}
    |> Sale.changeset(%{
      user_id: user.id,
      bundle_id: bundle_id,
      quantity: qty,
      total_price: total
    })
    |> Repo.insert!()
  end

  def list_sales do
    Sale
    |> preload([:user, :product, bundle: [bundle_items: :product]])
    |> order_by([s], desc: s.inserted_at)
    |> Repo.all()
  end

  def get_today_stats do
    today = Date.utc_today()

    query = from s in Sale,
      where: fragment("?::date", s.inserted_at) == ^today,
      select: {count(s.id), sum(s.total_price)}

    case Repo.one(query) do
      {count, total} -> %{count: count, total: total || Decimal.new(0)}
      nil -> %{count: 0, total: Decimal.new(0)}
    end
  end

  def list_recent_sales(limit \\ 5) do
    Sale
    |> preload([:user, :product, :bundle])
    |> order_by(desc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end
end
