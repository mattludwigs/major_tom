defmodule MajorTom.Satellites.SatelliteEngine do
  @moduledoc false

  use GenServer

  alias MajorTom.Satellites.{Events, Satellite}

  @orbiting_tick_interval 3000
  @operating_tick_interval 30 * 1000 # 30 seconds

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: via_name(opts))
  end

  defp via_name(opts) when is_list(opts) do
    name = Keyword.fetch!(opts, :name)
    {:via, Registry, {MajorTom.Satellite.Registry, name}}
  end

  defp via_name(name) do
    {:via, Registry, {MajorTom.Satellite.Registry, name}}
  end

  @impl GenServer
  def init(opts) do
    satellite_name = Keyword.fetch!(opts, :name)
    state = %{satellite: Satellite.new(satellite_name)}

    emit_telemetry_and_schedule_tick(state)

    {:ok, state}
  end

  def issue_command(satellite_name, command, args \\ []) do
    satellite_name
    |> via_name()
    |> GenServer.cast({:command, command, args})
  end

  @impl GenServer
  def handle_cast({:command, :launch, _args}, state) do
    %{satellite: satellite} = state

    # Rather than using an evented async system, we could easily have
    # stored the caller pid in teh state and replied directly that. However,
    # that would require tracking many callers pids and mapping the right
    # response by to that specific caller. I think for this case events are
    # fine but if need to route specific responses by to many callers, we could
    # implement that.
    #
    # I did this in Grizzly (https://github.com/smartrent/grizzly) due to wanting
    # synchronizing of async messages.
    Events.broadcast(satellite.call_sign, :satellite_launch_initiated, %{satellite: satellite})

    launch_satellite(state)
  end

  @impl GenServer
  def handle_info(:pre_orbit_tick, state) do
    launch_satellite(state)
  end

  def handle_info(:orbiting_tick, state) do
    %{satellite: satellite} = state

    satellite = Satellite.move(satellite, 10000.0)
    Events.broadcast(satellite.call_sign, :transmit_data, %{satellite: satellite})

    Process.send_after(self(), :orbiting_tick, @orbiting_tick_interval)

    {:noreply, %{state | satellite: satellite}}
  end

  def handle_info(:operating_tick, state) do
    %{satellite: satellite} = state

    satellite = Satellite.move(satellite, 1000.0)
    state = %{state | satellite: satellite}

    emit_telemetry_and_schedule_tick(state)
    {:noreply, state}
  end

  defp launch_satellite(state) do
    %{satellite: satellite} = state
    # make really small adjustments while we get into orbit
    adjustment_rate = 1000.0

    moved_satellite =
      satellite
      |> Satellite.set_power(25)
      |> Satellite.move(adjustment_rate)

    case moved_satellite do
      %{status: :in_orbit} = moved_satellite ->
        Events.broadcast(moved_satellite.call_sign, :satellite_in_orbit, %{
          satellite: moved_satellite
        })

        # bring orbiting power down to 10
        satellite = Satellite.set_power(moved_satellite, 10)
        Process.send_after(self(), :orbiting_tick, @orbiting_tick_interval)

        {:noreply, %{state | satellite: satellite}}

      %{status: :failed} = moved_satellite ->
        Events.broadcast(moved_satellite.call_sign, :satellite_launch_failed, %{
          satellite: moved_satellite
        })

        {:noreply, :error, %{state | satellite: moved_satellite}}

      %{status: :pre_orbit} = moved_satellite ->
        Process.send_after(self(), :pre_orbit_tick, 1000)

        {:noreply, %{state | satellite: moved_satellite}}
    end
  end

  defp emit_telemetry_and_schedule_tick(state) do
    %{satellite: satellite} = state

    Events.broadcast(satellite.call_sign, :transmit_telemetry, build_telemetry(satellite))
    Process.send_after(self(), :operating_tick, @operating_tick_interval)
  end

  defp build_telemetry(satellite) do
    %{
      call_sign: satellite.call_sign,
      power: satellite.power,
      battery: satellite.battery,
      altitude_km: satellite.altitude_km,
      orbit_phase: satellite.orbit_phase,
      total_cost: Satellite.total_cost(satellite)
    }
  end
end
