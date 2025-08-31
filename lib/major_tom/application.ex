defmodule MajorTom.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      MajorTom.Satellites.Events,
      # we will start a scoped process registry rather than start a global process
      # registry. This will keep the registry smaller if this scaled to a large
      # fleet with many other processes needing a process registry. However, Registries
      # use ETS under the hood and this should really scale regardless. It is just nice
      # in an OTP application to keep process management well scoped to avoid coupling and
      # adverse effects one type of process does not have any impact on another type.
      {Registry, keys: :unique, name: MajorTom.Satellite.Registry},
      {PartitionSupervisor, child_spec: DynamicSupervisor, name: MajorTom.Satellites.Supervisor},
      {PartitionSupervisor,
       child_spec: DynamicSupervisor, name: MajorTom.GroundStation.Supervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: MajorTom.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
