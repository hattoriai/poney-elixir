defmodule Poney.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/hattoriai/poney-elixir"

  def project do
    [
      app: :poney,
      version: @version,
      elixir: "~> 1.18",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases(),
      dialyzer: [
        plt_add_apps: [:mix, :ex_unit],
        plt_core_path: "priv/plts",
        plt_file: {:no_warn, "priv/plts/project.plt"}
      ],
      package: package(),
      docs: docs(),
      description: description(),
      name: "Poney",
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      # A full JSON Schema validator, for the tests only: it checks that
      # Poney.Schema reads the published schema as the standard says.
      # 0.28 or later: it takes idna 8, without the punycode advisory of 7.x.
      {:jsv, "~> 0.28.0", only: :test},
      {:stream_data, "~> 1.1", only: :test}
    ]
  end

  defp aliases do
    [
      # On an up-to-date main, after the release pull request: check the
      # repository, publish to Hex, then tag the version. The check runs in
      # a child VM: once anything compiles in this VM, Mix no longer finds
      # the tasks of the Hex archive.
      release: [
        "cmd mix poney.release_check",
        "hex.publish --yes",
        "cmd git tag v#{@version}",
        "cmd git push origin v#{@version}"
      ]
    ]
  end

  defp description do
    "The Poney format in Elixir: read, check and write Poney documents " <>
      "(software explained in diagrams), as the specification says."
  end

  defp package do
    [
      name: "poney",
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url, "Poney" => "https://github.com/hattoriai/poney"},
      files: ~w(lib priv/spec mix.exs .formatter.exs guides README.md CHANGELOG.md LICENSE NOTICE)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url,
      assets: %{"media" => "media"},
      extras: [
        "README.md",
        "guides/walkthroughs.md",
        "guides/conformance.md",
        "CHANGELOG.md"
      ],
      groups_for_modules: [
        Reading: [Poney, Poney.Issue, Poney.InvalidDocumentError, Poney.Ref],
        Document: [
          Poney.Document,
          Poney.Project,
          Poney.ExtensionUse,
          Poney.Presentation,
          Poney.Presentation.KindStyle,
          Poney.Presentation.LineStyle,
          Poney.Presentation.Override
        ],
        Model: [~r/^Poney\.Model/],
        Views: [~r/^Poney\.View/],
        Walkthroughs: [~r/^Poney\.Walkthrough/, ~r/^Poney\.Scene/]
      ]
    ]
  end
end
