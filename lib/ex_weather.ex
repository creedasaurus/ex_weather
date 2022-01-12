defmodule ExWeather do
  @moduledoc """
  ExWeather is a small example CLI application to fetch the weather for various
  locations using the https://www.metaweather.com API.

  The root module contains some basic common helper functions.
  """
  require Logger

  @doc """
  Gets the average of a list of integers

  ## Example

  iex> ExWeather.average([1, 2, 3, 4, 5])
  3.0
  """
  @spec average(nonempty_list(integer())) :: float
  def average(nums) when is_list(nums) and length(nums) > 0 do
    Process.sleep(100)
    Enum.sum(nums) / length(nums)
  end

  @spec latest_date(nonempty_list(Calendar.date())) :: Calendar.date()
  def latest_date(dates) do
    Enum.max_by(dates, & &1, Date)
  end

  @spec dates_until_days(Calendar.date(), integer()) :: [Calendar.date()]
  def dates_until_days(start_date, days) do
    Enum.map(1..days, &Date.add(start_date, &1))
  end
end
