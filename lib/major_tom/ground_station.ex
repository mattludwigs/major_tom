defmodule MajorTom.GroundStation do
  @moduledoc """
  Public API for ground station communication

  This is to mimic a ground station API
  """

  alias MajorTom.GroundStation.Supervisor, as: GSSupervisor

  def connect(satellite_name, opts \\ []) do
    opts
    |> Keyword.put(:satellite_name, satellite_name)
    |> GSSupervisor.start_child()
  end

  def init_orbit(conn) do
    GenServer.cast(conn, :init_orbit)
  end
end
