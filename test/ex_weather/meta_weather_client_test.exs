defmodule ExWeatherTest.MetaWeatherClientTest do
  use ExUnit.Case
  require Logger

  alias ExWeather.MetaWeatherClient

  test "API response maps to WeatherResponse" do
    location_id = "1111111111111"
    city_name = "Salt Lake City"
    url_to_match = "https://www.metaweather.com/api/location/#{location_id}/"

    Tesla.Mock.mock(fn env ->
      case env.url do
        ^url_to_match ->
          Tesla.Mock.json(%{
            "consolidated_weather" => [
              %{
                "id" => 1_111_111_111_111,
                "weather_state_name" => "Clear",
                "weather_state_abbr" => "c",
                "wind_direction_compass" => "SSE",
                "created" => "2022-01-11T02:29:16.566567Z",
                "applicable_date" => "2022-01-22",
                "min_temp" => -2.885,
                "max_temp" => 5.515000000000001,
                "the_temp" => 4.84,
                "wind_speed" => 3.3041241003393513,
                "wind_direction" => 154.7472518883886,
                "air_pressure" => 1035.0,
                "humidity" => 57,
                "visibility" => 12.703312654100056,
                "predictability" => 68
              },
              %{
                "id" => 1_111_111_111_111,
                "weather_state_name" => "Light Cloud",
                "weather_state_abbr" => "lc",
                "wind_direction_compass" => "ESE",
                "created" => "2022-01-11T02:29:19.385228Z",
                "applicable_date" => "2022-01-11",
                "min_temp" => -1.2349999999999999,
                "max_temp" => 5.66,
                "the_temp" => 5.73,
                "wind_speed" => 3.201116655330205,
                "wind_direction" => 120.4015860608264,
                "air_pressure" => 1033.5,
                "humidity" => 53,
                "visibility" => 14.151418217609162,
                "predictability" => 70
              }
            ],
            "title" => city_name,
            "woeid" => 1_111_111_111_111
          })
      end
    end)

    assert {:ok, data} = MetaWeatherClient.get_weather_for_location(location_id)

    assert length(data) == 2

    # Chech that they all have the title
    Enum.each(data, &assert(&1.title == city_name))

    # Check that even though their "applicable_date" came back out of
    # order, they are now in order
    [first, second] = data
    assert :lt == Date.compare(first.applicable_date, second.applicable_date)
  end

  test "Test the single date response" do
    location_id = "1111111111111"
    date = ~D[2020-01-22]

    url_to_match =
      "https://www.metaweather.com/api/location/#{location_id}/#{date.year}/#{date.month}/#{date.day}/"

    Tesla.Mock.mock(fn env ->
      case env.url do
        ^url_to_match ->
          Tesla.Mock.json([
            %{
              "id" => 1_111_111_111_111,
              "weather_state_name" => "Clear",
              "weather_state_abbr" => "c",
              "wind_direction_compass" => "SSE",
              "created" => "2022-01-11T02:29:16.566567Z",
              "applicable_date" => "2022-01-22",
              "min_temp" => -2.885,
              "max_temp" => 5.515000000000001,
              "the_temp" => 4.84,
              "wind_speed" => 3.3041241003393513,
              "wind_direction" => 154.7472518883886,
              "air_pressure" => 1035.0,
              "humidity" => 57,
              "visibility" => 12.703312654100056,
              "predictability" => 68
            },
            %{
              "id" => 1_111_111_111_111,
              "weather_state_name" => "Light Cloud",
              "weather_state_abbr" => "lc",
              "wind_direction_compass" => "ESE",
              "created" => "2022-01-11T02:29:19.385228Z",
              "applicable_date" => "2020-01-22",
              "min_temp" => -1.2349999999999999,
              "max_temp" => 5.66,
              "the_temp" => 5.73,
              "wind_speed" => 3.201116655330205,
              "wind_direction" => 120.4015860608264,
              "air_pressure" => 1033.5,
              "humidity" => 53,
              "visibility" => 14.151418217609162,
              "predictability" => 70
            }
          ])
      end
    end)

    assert {:ok, data} = MetaWeatherClient.get_weather_for_location_on_date(location_id, date)
    assert data.applicable_date == date
    # Because there is no "City name" that comes back on a particular date query,
    # the location_id is mapped to the `WeatherResponse.title`
    assert data.title == location_id
  end

  test "API response handles 404 not found with error" do
    location_id = "1111111111111"
    url_to_match = "https://www.metaweather.com/api/location/#{location_id}/"

    Tesla.Mock.mock(fn env ->
      case env.url do
        ^url_to_match -> {404, %{}}
      end
    end)

    assert {:error, _} = MetaWeatherClient.get_weather_for_location(location_id)
  end
end
