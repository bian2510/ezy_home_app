defmodule EzyHomeAppWeb.UserLive.Registration do
  use EzyHomeAppWeb, :live_view

  import EzyHomeAppWeb.CoreComponents
  alias EzyHomeApp.Accounts
  alias EzyHomeApp.Accounts.User

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash} current_scope={@current_scope}>
      <div class="mx-auto max-w-sm">
        <.header class="text-center">
          Registrar Nueva Tienda
          <:subtitle>
            Crea tu cuenta y empieza a gestionar tu stock.
          </:subtitle>
        </.header>

        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="save"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log-in?_action=registered"}
          method="post"
        >
          <.error :if={@check_errors}>
            Oops, algo salió mal. Revisa los errores abajo.
          </.error>
          <.input
            name="company[name]"
            value={@company_name}  label="Nombre de la Empresa"
            required
          />
          <.input field={@form[:email]} type="email" label="Email" required />
          <.input field={@form[:password]} type="password" label="Password" required />

          <:actions>
            <.button phx-disable-with="Creating account..." class="w-full">
              Crear Cuenta y Tienda
            </.button>
          </:actions>
        </.simple_form>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_scope: %{user: user}}} = socket)
      when not is_nil(user) do
    {:ok, redirect(socket, to: EzyHomeAppWeb.UserAuth.signed_in_path(socket))}
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false)
      |> assign(check_errors: false)
      |> assign(company_name: "")
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  @impl true
  def handle_event("save", %{"user" => user_params, "company" => company_params}, socket) do
    # Llamamos a nuestra nueva función que crea ambas cosas
    case Accounts.register_company_and_owner(company_params, user_params) do
      {:ok, %{user: user}} ->
        {:ok, _} = Accounts.deliver_user_confirmation_instructions(
          user,
          &url(~p"/users/confirm/#{&1}")
        )

        changeset = Accounts.change_user_registration(user)

        # Éxito: disparamos el submit para que el Controller haga el login
        {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

      {:error, :user, %Ecto.Changeset{} = changeset, _} ->
        # Falló el usuario (ej: email duplicado)
        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}

      {:error, :company, %Ecto.Changeset{} = _company_changeset, _} ->
        # Falló la empresa (ej: nombre duplicado).
        # Hack rápido: mostramos un error genérico en el flash o en el formulario.
        # Lo ideal sería manejar un changeset para la empresa también,
        # pero para empezar, usemos un put_flash.
        {:noreply, socket |> put_flash(:error, "Error al crear la empresa (quizás el nombre ya existe).")}
    end
  end

  @impl true
  def handle_event("validate", %{"user" => user_params}, socket) do
    company_name = get_in(user_params, ["company", "name"]) || ""
    changeset = Accounts.change_user_registration(%User{}, user_params)

    {:noreply,
     socket
     |> assign_form(Map.put(changeset, :action, :validate))
     |> assign(company_name: company_name)}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")
    assign(socket, form: form)
  end
end
