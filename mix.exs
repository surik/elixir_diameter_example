defmodule ElixirDiameterExample.Mixfile do
  use Mix.Project

  def project do
    [app: :elixir_diameter_example,
     version: "0.0.1",
     elixir: "~> 1.2",
     compilers: [:dia, :erlang, :elixir, :app],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :diameter],
     mod: {ElixirDiameterExample, []}]
  end

  defp deps do
    [
      {:mix_dia_compiler, "~> 0.2.0"}
    ]
  end
end
