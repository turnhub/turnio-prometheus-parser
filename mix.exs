defmodule PrometheusParser.MixProject do
  use Mix.Project

  def project do
    [
      app: :prometheus_parser,
      version: "0.1.5",
      elixir: "~> 1.11",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      description: description()
    ]
  end

  defp package() do
    [
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/turnhub/turnio-prometheus-parser"}
    ]
  end

  defp description() do
    "A nimble_parsec parser for parsing the Prometheus text format."
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
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false},
      {:nimble_parsec, "~> 1.1"},
      {:mix_test_watch, "~> 1.0", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
