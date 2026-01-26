defmodule EzyHomeAppWeb.InventoryLive.FormComponent do
  use EzyHomeAppWeb, :live_component

  alias EzyHomeApp.Inventory
  # Importamos CoreComponents para poder usar <.input> y <.button>
  import EzyHomeAppWeb.CoreComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <div class="mb-6 border-b border-gray-200 pb-4">
        <h2 class="text-xl font-bold text-gray-800">
          <%= @title %>
        </h2>
        <p class="text-sm text-gray-500">Completa los detalles del producto.</p>
      </div>

      <.form
        for={@form}
        id="product-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        class="space-y-6"
      >
        <.input field={@form[:name]} type="text" label="Nombre del Producto" placeholder="Ej: Hub Zigbee" />

        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:sku]} type="text" label="SKU (Único)" placeholder="HUB-01" />
          <.input field={@form[:price]} type="number" step="0.01" label="Precio ($)" />
        </div>

        <div class="grid grid-cols-2 gap-4">
          <.input field={@form[:current_stock]} type="number" label="Stock Actual" />
          <.input field={@form[:min_stock_threshold]} type="number" label="Alerta Mínimo" />
        </div>

        <div class="mt-6 flex items-center justify-end gap-x-3">
          <.link patch={@patch} class="text-sm font-semibold leading-6 text-gray-900 hover:text-gray-700">
            Cancelar
          </.link>

          <button
            type="submit"
            phx-disable-with="Guardando..."
            class="rounded-md bg-indigo-600 px-3 py-2 text-sm font-semibold text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600"
          >
            Guardar Producto
          </button>
        </div>
      </.form>
    </div>
    """
  end

  @impl true
  def update(%{product: product} = assigns, socket) do
    changeset = EzyHomeApp.Inventory.Schemas.Product.changeset(product, %{})

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"product" => product_params}, socket) do
    changeset =
      socket.assigns.product
      |> EzyHomeApp.Inventory.Schemas.Product.changeset(product_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, product_params) do
    case Inventory.update_product(socket.assigns.product, product_params) do
      {:ok, _product} ->
        send(self(), {:saved, "Producto actualizado correctamente"})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_product(socket, :new, product_params) do
    company_id = socket.assigns.current_company_id
    case Inventory.create_product(company_id, product_params) do
      {:ok, _product} ->
        send(self(), {:saved, "Producto creado exitosamente"})
        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset.errors, label: "❌ ERROR AL GUARDAR PRODUCTO")
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end
end
