defmodule ExWeatherTest do
  use ExUnit.Case

  test "Calculates average of some numbers" do
    assert ExWeather.average([1, 2, 3, 4, 5]) == 3.0
  end
end
