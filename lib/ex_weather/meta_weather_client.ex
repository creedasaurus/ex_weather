defmodule ExWeather.MetaWeatherClient do
  @moduledoc """
  The MetaWeatherClient module is a helper for calling the https://www.metaweather.com API
  and implements the `WeatherClient`.
  """
  @meta_weather_base_url "https://www.metaweather.com/api/"

  alias ExWeather.WeatherClient

  use Tesla
  plug(Tesla.Middleware.BaseUrl, @meta_weather_base_url)
  plug(Tesla.Middleware.JSON, engine_opts: [keys: :atoms])

  require Logger

  @behaviour WeatherClient

  @impl true
  def get_weather_for_location(location_id) do
    Logger.debug("Fetching #{location_id} from metaweather.com...")

    case get("/location/" <> location_id <> "/") do
      {:ok, response} ->
        handle_weather_response(location_id, response)

      {:error, _response} ->
        {:error, "Failed to make HTTP call"}
    end
  end

  @impl true
  def get_weather_for_location_on_date(location_id, date) do
    Logger.debug("Fetching data for #{location_id} on day: #{date}")

    with {:ok, response} <-
           get("/location/#{location_id}/#{date.year}/#{date.month}/#{date.day}/"),
         {:ok, parsed_response} <- handle_weather_response(location_id, response) do
      {:ok, parsed_response}
    else
      {:error, _response} ->
        {:error, "Failed to make HTTP call"}
    end
  end

  @spec handle_weather_response(String.t(), Tesla.Env.t()) ::
          {:error, any()}
          | {:ok, list(WeatherClient.WeatherResponse.t())}
          | {:ok, WeatherClient.WeatherResponse.t()}
  defp handle_weather_response(location_id, response) do
    case response do
      %Tesla.Env{status: 404} ->
        Logger.error("404 - location could not be found: #{location_id}")
        {:error, "location not found"}

      %Tesla.Env{body: body, status: 200} ->
        weather = flatten_weather_response(location_id, body)
        {:ok, weather}

      _ ->
        Logger.error("Failed to get valid response from metaweather")
        {:error, "did not get a valid response"}
    end
  end

  @spec flatten_weather_response(String.t(), struct() | list(struct())) ::
          list(WeatherClient.WeatherResponse.t()) | WeatherClient.WeatherResponse.t()

  defp flatten_weather_response(_location_id, parsed_json) when is_map(parsed_json) do
    title = parsed_json[:title]
    woeid = parsed_json[:woeid]
    consolidated_weather_data = parsed_json[:consolidated_weather]

    consolidated_weather_data
    |> Enum.map(&convert_raw_response(&1, title, woeid))
    |> Enum.sort_by(& &1.applicable_date, Date)
  end

  defp flatten_weather_response(location_id, parsed_json)
       when is_list(parsed_json) and length(parsed_json) > 0 do
    parsed_json
    |> Enum.map(&convert_raw_response(&1, location_id, location_id))
    |> Enum.sort_by(& &1.applicable_date, Date)
    |> Enum.at(0)
  end

  @spec convert_raw_response(struct(), String.t(), integer()) :: WeatherClient.WeatherResponse.t()
  defp convert_raw_response(raw_weather, title, woeid) do
    {:ok, parsed_date} = Date.from_iso8601(raw_weather[:applicable_date])

    %WeatherClient.WeatherResponse{
      location_id: woeid,
      title: title,
      applicable_date: parsed_date,
      min_temp: raw_weather[:min_temp],
      max_temp: raw_weather[:max_temp]
    }
  end
end
