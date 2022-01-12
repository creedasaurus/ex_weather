defmodule ExWeatherTest.WeatherManagerTest do
  use ExUnit.Case
  require Logger

  alias ExWeather.WeatherClient.WeatherResponse
  alias ExWeather.WeatherManager
  alias ExWeather.MetaWeatherClient

  import Mock

  describe "temperature_for_location/3" do
    test "Request is short by 1 day" do
      with_mock MetaWeatherClient,
        get_weather_for_location: fn _args ->
          {:ok,
           [
             %WeatherResponse{
               title: "Salt lake city",
               applicable_date: ~D[2020-10-01],
               max_temp: 1
             },
             %WeatherResponse{
               title: "Salt lake city",
               applicable_date: ~D[2020-10-02],
               max_temp: 2
             },
             %WeatherResponse{
               title: "Salt lake city",
               applicable_date: ~D[2020-10-03],
               max_temp: 3
             }
           ]}
        end,
        get_weather_for_location_on_date: fn _id, _date ->
          {:ok,
           %WeatherResponse{
             title: "Salt lake city",
             applicable_date: ~D[2020-10-04],
             max_temp: 4
           }}
        end do
        {:ok, temp_data} =
          WeatherManager.temperature_for_location(MetaWeatherClient, "11111111", 4)

        assert temp_data.avg_max == 2.5

        assert_called_exactly(MetaWeatherClient.get_weather_for_location(:_), 1)
        assert_called_exactly(MetaWeatherClient.get_weather_for_location_on_date(:_, :_), 1)
      end
    end

    test "First request provided more data than requested" do
      with_mock MetaWeatherClient,
        get_weather_for_location: fn _args ->
          {:ok,
           [
             %WeatherResponse{
               title: "Salt lake city",
               applicable_date: ~D[2020-10-01],
               max_temp: 1
             },
             %WeatherResponse{
               title: "Salt lake city",
               applicable_date: ~D[2020-10-02],
               max_temp: 2
             },
             %WeatherResponse{
               title: "Salt lake city",
               applicable_date: ~D[2020-10-03],
               max_temp: 3
             },
             %WeatherResponse{
               title: "Salt lake city",
               applicable_date: ~D[2020-10-04],
               max_temp: 4
             },
             %WeatherResponse{
               title: "Salt lake city",
               applicable_date: ~D[2020-10-04],
               max_temp: 99
             }
           ]}
        end do
        {:ok, temp_data} =
          WeatherManager.temperature_for_location(MetaWeatherClient, "11111111", 4)

        assert temp_data.avg_max == 2.5

        assert_called_exactly(MetaWeatherClient.get_weather_for_location(:_), 1)
        assert_not_called(MetaWeatherClient.get_weather_for_location_on_date(:_, :_))
      end
    end
  end
end
