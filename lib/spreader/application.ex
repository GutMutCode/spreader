defmodule Spreader.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      SpreaderWeb.Telemetry,
      Spreader.Repo,
      {DNSCluster, query: Application.get_env(:spreader, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Spreader.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Spreader.Finch},
      # Start a worker by calling: Spreader.Worker.start_link(arg)
      # {Spreader.Worker, arg},
      # Start to serve requests, typically the last entry
      SpreaderWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Spreader.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SpreaderWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
