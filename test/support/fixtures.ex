defmodule Poney.Fixtures do
  @moduledoc false

  # The files that `mix poney.spec` copies from a release of Poney.

  @spec json(Path.t()) :: map()
  def json(path), do: path |> File.read!() |> JSON.decode!()

  @spec example(String.t()) :: map()
  def example(name), do: json("test/fixtures/examples/#{name}.poney")

  @spec conformance() :: [map()]
  def conformance, do: json("test/conformance/manifest.json")["cases"]

  @spec conformance(String.t()) :: map()
  def conformance(file), do: json("test/conformance/#{file}")

  # The published JSON Schema, read by a full validator: the reference that
  # Poney.Schema must agree with.
  @spec jsv() :: JSV.Root.t()
  def jsv do
    case :persistent_term.get({__MODULE__, :jsv}, nil) do
      nil ->
        root = JSV.build!(json("priv/spec/poney.schema.json"))
        :persistent_term.put({__MODULE__, :jsv}, root)
        root

      root ->
        root
    end
  end
end
