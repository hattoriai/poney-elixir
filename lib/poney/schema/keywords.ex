defmodule Poney.Schema.Keywords do
  @moduledoc false

  # The keywords of a JSON Schema that are not in `known`, with where they
  # are. Poney.Schema runs this when it compiles: a schema keyword that it
  # does not interpret stops the build.

  @containers ~w(properties definitions)

  @spec unknown(map(), [String.t()]) :: [{String.t(), String.t()}]
  def unknown(schema, known), do: walk(schema, "#", MapSet.new(known))

  defp walk(schema, path, known) when is_map(schema) do
    Enum.flat_map(schema, fn
      {key, members} when key in @containers ->
        Enum.flat_map(members, fn {name, sub} -> walk(sub, "#{path}/#{key}/#{name}", known) end)

      {key, value} ->
        here = if MapSet.member?(known, key), do: [], else: [{path, key}]
        here ++ walk_value(key, value, "#{path}/#{key}", known)
    end)
  end

  defp walk(_schema, _path, _known), do: []

  # Literal data, not schemas.
  defp walk_value(key, _value, _path, _known) when key in ~w(default const enum required) do
    []
  end

  defp walk_value(_key, list, path, known) when is_list(list) do
    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {sub, i} -> walk(sub, "#{path}/#{i}", known) end)
  end

  defp walk_value(_key, value, path, known), do: walk(value, path, known)
end
