defmodule MajorTomTest do
  use ExUnit.Case
  doctest MajorTom

  test "greets the world" do
    assert MajorTom.hello() == :world
  end
end
