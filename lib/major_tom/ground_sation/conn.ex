defmodule MajorTom.GroundStation.Conn do
  @moduledoc """
  This is the "connection" between the ground station and the satellite.

  My in reality there isn't a persistent connection between ground radios
  and a satellite. However, this is opportunity to lean into the message
  passing and process monitoring that comes with OTP.

  One goal of this project is to simulate the distributed nature of communication
  between an operator's console, a ground station, and a satellite. So, to exercise
  our OTP skills, we will allow this process to be the intermeidary between a
  satellite and an operator. This is the "brains" of the ground station, just with
  an OTP flavor.
  """

  use GenServer

  require Logger

  alias MajorTom.Satellites

  @events [
    :satellite_launch_initiated,
    :satellite_in_orbit,
    :satellite_launch_failed,
    :satellite_orbiting
  ]

  def start_link(init_args) do
    GenServer.start_link(__MODULE__, init_args)
  end

  @impl GenServer
  def init(init_args) do
    operator = init_args[:operator]
    satellite_name = init_args[:satellite_name]

    with {:ok, pid} <- Satellites.initialize_satellite(satellite_name) do
      :ok = subscribe_events(satellite_name)
      monitor_ref = Process.monitor(pid)
      {:ok, %{operator: operator, satellite_name: satellite_name, monitor_ref: monitor_ref}}
    end
  end

  @impl GenServer
  def handle_cast(:init_orbit, state) do
    %{satellite_name: satellite_name} = state
    Satellites.start_orbit(satellite_name)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:DOWN, monitor_ref, :process, _pid, reason},
        %{monitor_ref: monitor_ref} = state
      ) do
    %{operator: operator, satellite_name: satellite_name} = state

    send(operator, {:satellite_down, satellite_name, reason})

    {:noreply, %{state | monitor_ref: nil}}
  end

  def handle_info({:major_tom, event, %{satellite: satellite}}, state) do
    Logger.debug("Received event: #{event} for satellite: #{satellite.call_sign}")

    {:noreply, state}
  end

  defp subscribe_events(satellite_name) do
    for event <- @events do
      Satellites.subscribe(satellite_name, event)
    end

    :ok
  end
end
