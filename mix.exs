defmodule Winter.MixProject do
  use Mix.Project

  def project do
    [
      app: :winter,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Winter.Application, []}
    ]
  end

  defp deps do
    [
      {:horde, "== 0.8.5"},
      {:libcluster, "== 3.3.0"}
    ]
  end

  defp releases do
    [
      winter: [
        include_executables_for: [:unix],
        applications: [runtime_tools: :permanent]
      ]
    ]
  end
end
