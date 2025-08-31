defmodule MajorTom.Satellites.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  alias MajorTom.Satellites.SatelliteEngine

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args)
  end

  @impl DynamicSupervisor
  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(args) do
    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {__MODULE__, self()}},
      {SatelliteEngine, args}
    )
  end
end
