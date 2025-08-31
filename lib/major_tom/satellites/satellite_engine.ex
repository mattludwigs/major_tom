defmodule MajorTom.Satellites.SatelliteEngine do
  @moduledoc false

  use GenServer

  @orbiting_tick_interval 3000

  alias MajorTom.Satellites.{Events, Satellite}

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

    {:ok, %{satellite: Satellite.new(satellite_name)}}
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
end
