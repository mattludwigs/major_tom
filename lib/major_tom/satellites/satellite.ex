defmodule MajorTom.Satellites.Satellite do
  @moduledoc """
  A satellite

  """

  @type movement_event() :: %{
          end_phase: float(),
          start_phase: float(),
          delta: float(),
          cost: float(),
          timestamp: integer()
        }

  @type t() :: %__MODULE__{
          orbit_phase: float() | nil,
          altitude_km: float(),
          status: :pre_orbit | :in_orbit | :failed,
          power: float(),
          battery: float(),
          call_sign: String.t(),
          movement_log: [movement_event()]
        }

  # power level is 1-100

  @enforce_keys [:call_sign]
  defstruct orbit_phase: nil,
            altitude_km: 0.0,
            status: :pre_orbit,
            power: 0.0,
            battery: 100.0,
            call_sign: nil,
            movement_log: []

  def new(call_sign) do
    %__MODULE__{call_sign: call_sign}
  end

  def set_power(satellite, power) do
    %{satellite | power: power}
  end

  def move(satellite, rate) do
    movement = get_movement(satellite, rate)
    # TODO make this more based off the movement and power level
    battery_used = :rand.uniform()
    new_battery = max(satellite.battery - battery_used, 0.0)

    if movement.end_phase > 0.1 do
      %{
        satellite
        | status: :in_orbit,
          battery: new_battery,
          orbit_phase: movement.end_phase,
          movement_log: [movement | satellite.movement_log]
      }
    else
      %{satellite | orbit_phase: movement.end_phase}
    end
  end

  defp get_movement(satellite, scale) do
    %__MODULE__{power: power, orbit_phase: orbit_phase} = satellite
    # to add some noise it the system isn't that deterministic
    # noise = :rand.uniform()
    delta = power / scale - 0.0
    new_orbit_phase = calc_new_orbit_phase(satellite, delta)
    # simulation for trying to understand the cost to the movement
    # we will assume for the sim the duration is already a second
    # and the base cost to just consider moving is 100 bucks....
    meter_per_second_cost = (1 + satellite.power) * (delta * 100) * 100.00

    %{
      end_phase: new_orbit_phase,
      start_phase: orbit_phase,
      delta: delta,
      cost: meter_per_second_cost,
      timestamp: DateTime.utc_now() |> DateTime.to_unix()
    }
  end

  def calc_new_orbit_phase(%__MODULE__{orbit_phase: nil}, delta) do
    Float.floor(delta, 2)
  end

  def calc_new_orbit_phase(satellite, delta) do
    Float.floor(delta, 2) + satellite.orbit_phase
  end
end
