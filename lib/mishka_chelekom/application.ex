defmodule MishkaChelekom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MishkaChelekomWeb.Telemetry,
      MishkaChelekom.Repo,
      {DNSCluster, query: Application.get_env(:mishka_chelekom, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: MishkaChelekom.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: MishkaChelekom.Finch},
      # Start a worker by calling: MishkaChelekom.Worker.start_link(arg)
      # {MishkaChelekom.Worker, arg},
      # Start to serve requests, typically the last entry
      MishkaChelekomWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MishkaChelekom.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    MishkaChelekomWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
