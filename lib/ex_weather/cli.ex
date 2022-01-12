defmodule ExWeather.CLI do
  @moduledoc """
  Encapsulates the CLI portion of the weather checker logic. This includes
  the commands/options parsing and orchestration.
  """
  alias ExWeather.WeatherManager
  alias ExWeather.MetaWeatherClient
  require Logger

  @default_days 6
  @max_days 10
  @default_concurrency 5

  @spec main(any) :: :ok
  def main(argv) do
    {options, args, _} =
      OptionParser.parse(
        argv,
        cli_options()
      )

    {enable_verbose, remaining_options} = Keyword.pop(options, :verbose)
    options = remaining_options

    if enable_verbose do
      Logger.configure(level: :debug)
    end

    Logger.debug(inspect(options))
    Logger.debug(inspect(args))

    print_help = Keyword.get(options, :help, false)
    num_days = Keyword.get(options, :days, @default_days)

    if num_days > @max_days do
      Logger.warn("Requesting too many days: #{num_days}. Max: #{@max_days}")
      exit("--days max: #{@max_days}")
    end

    max_concurrency = Keyword.get(options, :concurrency, @default_concurrency)

    case {print_help, args} do
      {true, []} ->
        print_help_text()

      {false, locations} ->
        get_weather_for_locations(locations, num_days, max_concurrency)

      _ ->
        print_help_text()
    end
  end

  defp get_weather_for_locations(location_ids, num_days, max_concurrency) do
    Logger.debug(
      "getting max average temperature for #{inspect(location_ids)} for days: #{num_days}"
    )

    location_ids
    |> Task.async_stream(&fetch_avg_max_temp_for_location(&1, num_days),
      ordered: false,
      max_concurrency: max_concurrency
    )
    |> Stream.map(fn {:ok, res} -> res end)
    |> Enum.into([], fn {:ok, res} -> res end)
    |> Enum.each(fn %WeatherManager.TemperatureResponse{} = temp_response ->
      IO.puts("#{temp_response.title} Average Max Temp: #{Float.round(temp_response.avg_max, 2)}")
    end)
  end

  def fetch_avg_max_temp_for_location(location_id, num_days) do
    case WeatherManager.temperature_for_location(MetaWeatherClient, location_id, num_days) do
      {:ok, temp_response} ->
        {:ok, temp_response}

      {:error, message} ->
        Logger.error("Failed to fetch weather data: #{message}")
        {:error, message}
    end
  end

  @spec cli_options() :: OptionParser.options()
  defp cli_options do
    [
      strict: [
        help: :boolean,
        verbose: :boolean,
        days: :integer,
        concurrency: :integer
      ],
      aliases: [
        h: :help,
        v: :verbose,
        d: :days,
        c: :concurrency
      ]
    ]
  end

  @spec print_help_text() :: :ok
  defp print_help_text() do
    IO.puts("""
    ex_weather is a toy project to test out some Elixir.

    USAGE:
      ex_weather [OPTIONS] INPUT
    OPTIONS:
      -h, --help
      -v, --verbose     Set the log output to debug level
      -c, --concurrency Set the maximum concurrency for the http calls
                          (default: 5)
      -d, --days        Number of days to average the max_temp
                          (default: 6, max: 10) -- after so many days, there isn't much data
    INPUT:
      <locations>...    The location(s) ID or "woeid" (Where on earth identifier)
                          see: https://www.findmecity.com/

    Example:
      Get the average max_temp for SLC, LA, and NYC
      $ ex_weather 2487610 2442047 2459115

      Get the average max_temp for LA over 3 days
      $ ex_weather --days 3 2442047
    """)
  end
end
