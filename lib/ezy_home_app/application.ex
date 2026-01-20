defmodule EzyHomeApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      EzyHomeAppWeb.Telemetry,
      EzyHomeApp.Repo,
      {DNSCluster, query: Application.get_env(:ezy_home_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: EzyHomeApp.PubSub},
      # Start a worker by calling: EzyHomeApp.Worker.start_link(arg)
      # {EzyHomeApp.Worker, arg},
      # Start to serve requests, typically the last entry
      EzyHomeAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: EzyHomeApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    EzyHomeAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
