defmodule ExWeather.WeatherManager do
  @moduledoc """
  The WeatherManager is a higher level client for getting certain weather
  aspects.
  """
  require Logger
  alias ExWeather.WeatherClient
  alias ExWeather.MetaWeatherClient

  defmodule TemperatureResponse do
    @type t :: %__MODULE__{
            title: String.t(),
            avg_max: float()
          }

    defstruct [:title, :avg_max]
  end

  @type temp_response ::
          {:error, any()} | {:ok, TemperatureResponse.t()}

  @spec temperature_for_location(any(), String.t(), integer()) :: temp_response()
  def temperature_for_location(client \\ MetaWeatherClient, location_id, days) do
    Logger.debug("Getting temperature data for location #{location_id}")

    case client.get_weather_for_location(location_id) do
      {:ok, response} ->
        handle_weather_response(client, response, location_id, days)

      {:error, error} ->
        Logger.error(inspect(error))
        {:error, "failed to fetch tempurature data"}
    end
  end

  @spec handle_weather_response(
          any(),
          list(WeatherClient.WeatherResponse.t()),
          String.t(),
          integer()
        ) ::
          temp_response()
  defp handle_weather_response(client, weather_data, location_id, requested_days) do
    response_length = Enum.count(weather_data)
    title = Enum.at(weather_data, 0).title

    cond do
      response_length == requested_days ->
        avg_max =
          weather_data
          |> Enum.map(& &1.max_temp)
          |> Enum.to_list()
          |> ExWeather.average()

        {:ok,
         %TemperatureResponse{
           title: title,
           avg_max: avg_max
         }}

      response_length > requested_days ->
        Logger.debug(
          "Requested #{requested_days} days, but received #{response_length} from the API."
        )

        avg_max =
          weather_data
          |> Enum.take(requested_days)
          |> Enum.map(& &1.max_temp)
          |> Enum.to_list()
          |> ExWeather.average()

        {:ok,
         %TemperatureResponse{
           title: title,
           avg_max: avg_max
         }}

      0 < response_length and response_length < requested_days ->
        days_short = requested_days - response_length
        Logger.debug("Short by: #{days_short} days. Requesting additional data...")

        latest_datum = Enum.max_by(weather_data, & &1.applicable_date, Date)
        dates_to_fetch = ExWeather.dates_until_days(latest_datum.applicable_date, days_short)

        remaining_data = async_get_by_dates(client, location_id, dates_to_fetch)
        final_batch = weather_data ++ remaining_data

        avg_max =
          final_batch
          |> Enum.map(& &1.max_temp)
          |> Enum.to_list()
          |> ExWeather.average()

        {:ok,
         %TemperatureResponse{
           title: title,
           avg_max: avg_max
         }}
    end
  end

  defp async_get_by_dates(client, location_id, dates) do
    Logger.debug(
      "Async fetching weather for location: #{location_id} on dates: #{inspect(dates)}"
    )

    dates
    |> Task.async_stream(&get_location_data_for_date(client, location_id, &1), ordered: true)
    |> Stream.filter(&match?({:ok, _}, &1))
    |> Stream.map(fn {:ok, res} -> res end)
    |> Enum.into([], fn {:ok, res} -> res end)
  end

  defp get_location_data_for_date(client, location_id, date) do
    case client.get_weather_for_location_on_date(location_id, date) do
      {:ok, weather_response} ->
        {:ok, weather_response}

      {:error, _} ->
        err_msg = "failed to fetch for location: #{location_id} on #{Date.to_iso8601(date)}"
        Logger.error(err_msg)
        {:error, err_msg}
    end
  end
end
