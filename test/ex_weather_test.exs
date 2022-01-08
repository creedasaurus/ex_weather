defmodule ExWeatherTest do
  use ExUnit.Case
  doctest ExWeather

  test "greets the world" do
    assert ExWeather.hello() == :world
  end
end
