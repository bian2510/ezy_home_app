defmodule EzyHomeAppWeb.CoreComponents do
  @moduledoc """
  Componentes UI principales de la aplicación.
  """
  use Phoenix.Component
  use Gettext, backend: EzyHomeAppWeb.Gettext

  alias Phoenix.LiveView.JS

  @doc """
  Renders flash notices.
  """
  attr :id, :string, doc: "the optional id of flash container"
  attr :flash, :map, default: %{}, doc: "the map of flash messages to display"
  attr :title, :string, default: nil
  attr :kind, :atom, values: [:info, :error], doc: "used for styling and flash lookup"
  attr :rest, :global, doc: "the arbitrary HTML attributes to add to the flash container"

  slot :inner_block, doc: "the optional inner block that renders the flash message"

  def flash(assigns) do
    assigns = assign_new(assigns, :id, fn -> "flash-#{assigns.kind}" end)

    ~H"""
    <div
      :if={msg = render_slot(@inner_block) || Phoenix.Flash.get(@flash, @kind)}
      id={@id}
      phx-click={JS.push("lv:clear-flash", value: %{key: @kind}) |> hide("##{@id}")}
      role="alert"
      class={[
        "fixed top-2 right-2 mr-2 w-80 sm:w-96 z-50 rounded-lg p-3 shadow-lg ring-1 transition-all",
        @kind == :info && "bg-emerald-50 text-emerald-800 ring-emerald-500 fill-emerald-900",
        @kind == :error && "bg-rose-50 text-rose-900 ring-rose-500 fill-rose-900"
      ]}
      {@rest}
    >
      <p :if={@title} class="flex items-center gap-1.5 text-sm font-semibold leading-6">
        <.icon :if={@kind == :info} name="hero-information-circle-mini" class="h-4 w-4" />
        <.icon :if={@kind == :error} name="hero-exclamation-circle-mini" class="h-4 w-4" />
        {@title}
      </p>
      <p class="mt-2 text-sm leading-5">{msg}</p>
      <button type="button" class="group absolute top-1 right-1 p-2" aria-label={gettext("close")}>
        <.icon name="hero-x-mark-mini" class="h-5 w-5 opacity-40 group-hover:opacity-70" />
      </button>
    </div>
    """
  end

  @doc """
  Renders a button.
  """
  attr :type, :string, default: nil
  attr :class, :string, default: nil
  attr :rest, :global, include: ~w(disabled form name value)
  slot :inner_block, required: true

  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "phx-submit-loading:opacity-75 rounded-lg bg-zinc-900 hover:bg-zinc-700 py-2 px-3",
        "text-sm font-semibold leading-6 text-white active:text-white/80",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  # ===========================================================================
  # SECCIÓN DE INPUTS (Corregida y unificada a Tailwind)
  # ===========================================================================

  attr :id, :any, default: nil
  attr :name, :any
  attr :label, :string, default: nil
  attr :value, :any

  attr :type, :string,
    default: "text",
    values: ~w(checkbox color date datetime-local email file month number password
               search select tel text textarea time url week)

  attr :field, Phoenix.HTML.FormField, doc: "a form field struct retrieved from the form"
  attr :errors, :list, default: []
  attr :checked, :boolean, doc: "the checked flag for checkbox inputs"
  attr :prompt, :string, default: nil, doc: "the prompt for select inputs"
  attr :options, :list, doc: "the options to pass to Phoenix.HTML.Form.options_for_select/2"
  attr :multiple, :boolean, default: false, doc: "the multiple flag for select inputs"
  attr :class, :string, default: nil, doc: "the input class to use over defaults"

  attr :rest, :global,
    include: ~w(accept autocomplete capture cols disabled form list max maxlength min minlength
                multiple pattern placeholder readonly required rows size step)

  # 1. Wrapper principal
  def input(%{field: %Phoenix.HTML.FormField{} = field} = assigns) do
    errors = if Phoenix.Component.used_input?(field), do: field.errors, else: []

    assigns
    |> assign(field: nil, id: assigns.id || field.id)
    |> assign(:errors, Enum.map(errors, &translate_error(&1)))
    |> assign_new(:name, fn -> if assigns.multiple, do: field.name <> "[]", else: field.name end)
    |> assign_new(:value, fn -> field.value end)
    |> input()
  end

  # 2. Checkbox
  def input(%{type: "checkbox"} = assigns) do
    assigns = assign_new(assigns, :checked, fn -> Phoenix.HTML.Form.normalize_value("checkbox", assigns[:value]) end)

    ~H"""
    <div phx-feedback-for={@name} class="mb-4 flex items-center gap-2">
      <input type="hidden" name={@name} value="false" disabled={@rest[:disabled]} />
      <input
        type="checkbox"
        id={@id}
        name={@name}
        value="true"
        checked={@checked}
        class="h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600"
        {@rest}
      />
      <label for={@id} class="text-sm text-gray-900">{@label}</label>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  # 3. Select
  def input(%{type: "select"} = assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-4">
      <label for={@id} class="block text-sm font-medium leading-6 text-gray-900 mb-1">{@label}</label>
      <select
        id={@id}
        name={@name}
        class="block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6"
        multiple={@multiple}
        {@rest}
      >
        <option :if={@prompt} value="">{@prompt}</option>
        {Phoenix.HTML.Form.options_for_select(@options, @value)}
      </select>
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  @doc """
  Renders a simple form.

  ## Examples

      <.simple_form for={@form} phx-change="validate" phx-submit="save">
        <.input field={@form[:email]} label="Email"/>
        <.input field={@form[:username]} label="Username" />
        <:actions>
          <.button>Save</.button>
        </:actions>
      </.simple_form>
  """
  attr :for, :any, required: true, doc: "the datastructure for the form"
  attr :as, :any, default: nil, doc: "the server side parameter to collect all input under"

  attr :rest, :global,
    include: ~w(autocomplete name rel action enctype method novalidate target multipart),
    doc: "the arbitrary HTML attributes to apply to the form tag"

  slot :inner_block, required: true
  slot :actions, doc: "the slot for form actions, such as a submit button"

  def simple_form(assigns) do
    ~H"""
    <.form :let={f} for={@for} as={@as} {@rest}>
      <div class="mt-10 space-y-8 bg-white">
        {render_slot(@inner_block, f)}
        <div :for={action <- @actions} class="mt-2 flex items-center justify-between gap-6">
          {render_slot(action, f)}
        </div>
      </div>
    </.form>
    """
  end

  @doc """
  Renders a label.
  """
  attr :for, :string, default: nil
  slot :inner_block, required: true

  def label(assigns) do
    ~H"""
    <label for={@for} class="block text-sm font-medium leading-6 text-gray-900">
      {render_slot(@inner_block)}
    </label>
    """
  end

  # 4. Input Genérico (Texto, números, etc)
  def input(assigns) do
    ~H"""
    <div phx-feedback-for={@name} class="mb-4">
      <label for={@id} class="block text-sm font-medium leading-6 text-gray-900 mb-1">{@label}</label>
      <input
        type={@type}
        name={@name}
        id={@id}
        value={Phoenix.HTML.Form.normalize_value(@type, @value)}
        class={[
          "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6",
          @errors != [] && "ring-red-500 focus:ring-red-500 pr-10",
          @class
        ]}
        {@rest}
      />
      <.error :for={msg <- @errors}>{msg}</.error>
    </div>
    """
  end

  def error(assigns) do
    ~H"""
    <p class="mt-1 flex gap-2 items-center text-sm text-red-600 phx-no-feedback:hidden">
      <.icon name="hero-exclamation-circle-mini" class="h-4 w-4" />
      {render_slot(@inner_block)}
    </p>
    """
  end

  # ===========================================================================
  # MODAL (Corregido el error de JS ID)
  # ===========================================================================

  attr :id, :string, required: true
  attr :show, :boolean, default: false
  attr :on_cancel, :any, default: "#"
  slot :inner_block, required: true

  def modal(assigns) do
    ~H"""
    <div
      id={@id}
      phx-mounted={@show && show_modal(@id)}
      phx-remove={hide_modal(@id)}
      data-cancel={@on_cancel && JS.patch(@on_cancel)}
      class="relative z-50 hidden"
    >
      <div id={"#{@id}-bg"} class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity" aria-hidden="true" />
      <div class="fixed inset-0 z-10 w-screen overflow-y-auto">
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <div
            id={"#{@id}-container"}
            class="relative transform overflow-hidden rounded-lg bg-white px-4 pb-4 pt-5 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-lg sm:p-6"
          >
            <div class="absolute right-0 top-0 pr-4 pt-4">
              <button
                phx-click={JS.exec("data-cancel", to: "##{@id}")}
                type="button"
                class="rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none"
              >
                <span class="sr-only">Cerrar</span>
                <.icon name="hero-x-mark" class="h-6 w-6" />
              </button>
            </div>
            {render_slot(@inner_block)}
          </div>
        </div>
      </div>
    </div>
    """
  end

  def show_modal(js \\ %JS{}, id) do
    js
    |> JS.show(to: "##{id}")
    |> JS.show(to: "##{id}-bg", transition: {"transition-all transform ease-out duration-300", "opacity-0", "opacity-100"})
    |> JS.show(to: "##{id}-container", transition: {"transition-all transform ease-out duration-300", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95", "opacity-100 translate-y-0 sm:scale-100"})
    |> JS.add_class("overflow-hidden", to: "body")
    |> JS.focus_first(to: "##{id}-container") # <-- ESTO ESTÁ CORREGIDO
  end

  def hide_modal(js \\ %JS{}, id) do
    js
    |> JS.hide(to: "##{id}-bg", transition: {"transition-all transform ease-in duration-200", "opacity-100", "opacity-0"})
    |> JS.hide(to: "##{id}-container", transition: {"transition-all transform ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"})
    |> JS.hide(to: "##{id}", time: 200)
    |> JS.remove_class("overflow-hidden", to: "body")
    |> JS.pop_focus()
  end

  # ===========================================================================
  # OTROS HELPERS
  # ===========================================================================

  attr :name, :string, required: true
  attr :class, :string, default: "size-4"
  attr :rest, :global
  def icon(assigns) do
    ~H"""
    <span class={[@name, @class]} {@rest} />
    """
  end

  def header(assigns) do
    ~H"""
    <header class="flex items-center justify-between gap-6 pb-4">
      <div><h1 class="text-lg font-semibold leading-8">{render_slot(@inner_block)}</h1></div>
    </header>
    """
  end

  def hide(js \\ %JS{}, selector) do
    JS.hide(js, to: selector, time: 200, transition: {"transition-all ease-in duration-200", "opacity-100 translate-y-0 sm:scale-100", "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95"})
  end

  @doc """
  Shows an element by fading it in.
  """
  def show(js \\ %JS{}, selector) do
    JS.show(js,
      to: selector,
      time: 300,
      transition:
        {"transition-all ease-out duration-300",
         "opacity-0 translate-y-4 sm:translate-y-0 sm:scale-95",
         "opacity-100 translate-y-0 sm:scale-100"}
    )
  end

  def translate_error({msg, opts}) do
    if count = opts[:count], do: Gettext.dngettext(EzyHomeAppWeb.Gettext, "errors", msg, msg, count, opts), else: Gettext.dgettext(EzyHomeAppWeb.Gettext, "errors", msg, opts)
  end
end
