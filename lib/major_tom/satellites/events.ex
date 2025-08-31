defmodule MajorTom.Satellites.Events do
  @moduledoc """
  Event bus for PubSub messaging


  Under the hood we use registry so that process and can register for
  events. Right now we are going to just a singelton register but if scale was
  a consideration we could make my registries based off different event sources
  and handle the routing for those sources transparently.

  Note: This uses atoms as events. While simple, once an application goes the
  atom based events become a little challenging to maintain.
  """

  def child_spec(_) do
    Registry.child_spec(keys: :duplicate, name: __MODULE__)
  end

  def subscribe(satellite_name, event) do
    Registry.register(__MODULE__, key(satellite_name, event), [])
  end

  def unsubscribe(satellite_name, event) do
    Registry.unregister(__MODULE__, key(satellite_name, event))
  end

  def broadcast(satellite_name, event, payload \\ %{}) do
    Registry.dispatch(__MODULE__, key(satellite_name, event), fn entries ->
      for {pid, _} <- entries do
        send(pid, {:major_tom, event, payload})
      end
    end)
  end

  defp key(satellite_name, event) do
    {satellite_name, event}
  end
end
