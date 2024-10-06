defmodule Cunha.MixProject do
  use Mix.Project

  def project do
    [
      app: :cunha,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Cunha.Application, []}
    ]
  end

  defp deps do
    [
      {:nostrum, "~> 0.10"},
      {:httpoison, "~> 1.8"},
      {:jason, "~> 1.2"}
    ]
  end
end
