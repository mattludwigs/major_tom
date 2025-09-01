defmodule MajorTom do
  @moduledoc """
  This Module this the primary "user" facing system control, you can think of
  this a the operator of the satellites.

  The operator isn't automatically started so that we can provide
  configuration options for the operator at runtime more easily.

  This will allow us to test with different simulations
  """

  use GenServer

  require Logger

  alias MajorTom.GroundStation

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    {:ok, %{satellites: %{}}}
  end

  def connect(name) do
    GenServer.call(__MODULE__, {:connect, name})
  end

  def list_satellites() do
    GenServer.call(__MODULE__, :list_satellites)
  end

  def init_orbit(satellite_name) do
    GenServer.call(__MODULE__, {:init_orbit, satellite_name})
  end

  @impl GenServer
  def handle_call({:connect, name}, _from, state) do
    %{satellites: satellites} = state

    if Map.has_key?(satellites, name) do
      {:reply, {:error, :already_connected}, state}
    else
      case GroundStation.connect(name) do
        {:ok, conn} ->
          {:reply, :ok, %{state | satellites: Map.put(satellites, name, conn)}}

        {:error, reason} ->
          {:reply, {:error, reason}, state}
      end
    end
  end

  def handle_call(:list_satellites, _from, state) do
    %{satellites: satellites} = state
    {:reply, Map.keys(satellites), state}
  end

  def handle_call({:init_orbit, satellite_name}, _from, state) do
    case Map.get(state.satellites, satellite_name) do
      nil ->
        {:reply, {:error, :satellite_not_found}, state}

      conn ->
        :ok = GroundStation.init_orbit(conn)
        {:reply, :ok, state}
    end
  end

  @impl GenServer
  def handle_info({:satellite_telemetry, telemetry}, state) do
    # TODO: push to influxdb
    dbg("Received telemetry for satellite: #{telemetry.call_sign}")

    {:noreply, state}
  end
end
