defmodule MajorTom.GroundStation.Supervisor do
  @moduledoc false

  use DynamicSupervisor

  alias MajorTom.GroundStation.Conn

  def start_link(init_args) do
    Supervisor.start_link(__MODULE__, init_args)
  end

  @impl DynamicSupervisor
  def init(_init_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(opts) do
    # ensure we have access to the operator
    args = Keyword.put_new(opts, :operator, self())

    DynamicSupervisor.start_child(
      {:via, PartitionSupervisor, {__MODULE__, self()}},
      {Conn, args}
    )
  end
end
