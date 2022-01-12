defmodule ExWeather.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_weather,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      escript: escript(),
      deps: deps()
    ]
  end

  def escript do
    [
      main_module: ExWeather.CLI,
      comment: "A script to get me the weather",
      path: "_build/ex_weather"
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # HTTP client
      {:tesla, "~> 1.4"},
      {:hackney, "~> 1.17"},
      {:jason, ">= 1.0.0"},
      {:mock, "~> 0.3.0", only: :test}
    ]
  end
end
