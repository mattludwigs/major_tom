defmodule MajorTom.Satellites do
  @moduledoc """
  Public API for satellites
  """

  alias MajorTom.Satellites.Supervisor, as: SatelliteSupervisor
  alias MajorTom.Satellites.{Events, SatelliteEngine}

  def initialize_satellite(name) do
    SatelliteSupervisor.start_child(name: name)
  end

  def start_orbit(satellite_name) do
    SatelliteEngine.issue_command(satellite_name, :launch)
  end

  def subscribe(satellite_name, event) do
    Events.subscribe(satellite_name, event)
  end

  def unsubscribe(satellite_name, event) do
    Events.unsubscribe(satellite_name, event)
  end
end
