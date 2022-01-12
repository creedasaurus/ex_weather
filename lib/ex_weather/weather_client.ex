defmodule ExWeather.WeatherClient do
  @moduledoc """
  The WeatherClient defines the types and behavior a weather forecasting client
  should implement. Whatever the weather source, it should be able to convert
  the response to a `WeatherResponse`
  """

  defmodule WeatherResponse do
    @type t :: %__MODULE__{
            location_id: integer(),
            title: String.t(),
            applicable_date: Calendar.date(),
            min_temp: number(),
            max_temp: number()
          }

    defstruct [:location_id, :title, :applicable_date, :min_temp, :max_temp]
  end

  @type batch_weather_response ::
          {:error, any()} | {:ok, [WeatherResponse.t()]}
  @type singular_weather_response ::
          {:error, any()} | {:ok, WeatherResponse.t()}
  @doc """
  Get the weather for a given location using the location ID
  """
  @callback get_weather_for_location(String.t()) :: batch_weather_response

  @doc """
  Get the weather forecast for a location on a particular date
  """
  @callback get_weather_for_location_on_date(String.t(), Calendar.date()) ::
              singular_weather_response
end
