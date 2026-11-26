defmodule Poney.Writer do
  @moduledoc false

  # A document's structs back to JSON: members in the order the format
  # lists them, optional members left out when they are nil, and open maps
  # (`ext`, `metadata`, styles by kind) by key. The text is indented by two
  # spaces, as JavaScript's JSON.stringify(doc, null, 2) writes it, so a file
  # this library writes reads and diffs like one from the other tools.

  # An object whose members keep their order.
  @typep ordered ::
           {:object, [{String.t(), ordered()}]}
           | [ordered()]
           | String.t()
           | number()
           | boolean()
           | nil

  @doc "The document as JSON: maps with string keys."
  @spec to_json(struct()) :: map()
  def to_json(%module{} = struct), do: struct |> ordered(module) |> plain()

  @doc "The document as JSON text, indented, with a final newline."
  @spec to_text(struct()) :: String.t()
  def to_text(%module{} = struct),
    do: IO.iodata_to_binary([print(ordered(struct, module), ""), ?\n])

  @spec ordered(term(), term()) :: ordered()
  defp ordered(%module{} = struct, _type) do
    # Only nil is left out: false and empty values are the document's.
    {:object,
     Enum.flat_map(module.fields(), fn {name, key, type} ->
       case Map.fetch!(struct, name) do
         nil -> []
         value -> [{key, ordered(value, type)}]
       end
     end)}
  end

  defp ordered(list, {:list, type}), do: Enum.map(list, &ordered(&1, type))

  defp ordered(map, {:map, type}),
    do: {:object, map |> Enum.sort() |> Enum.map(fn {k, v} -> {k, ordered(v, type)} end)}

  defp ordered(value, _type), do: open(value)

  # JSON the format leaves open, such as an extension's data.
  defp open(map) when is_map(map),
    do: {:object, map |> Enum.sort() |> Enum.map(fn {k, v} -> {to_string(k), open(v)} end)}

  defp open(list) when is_list(list), do: Enum.map(list, &open/1)
  defp open(value), do: value

  defp plain({:object, members}), do: Map.new(members, fn {k, v} -> {k, plain(v)} end)
  defp plain(list) when is_list(list), do: Enum.map(list, &plain/1)
  defp plain(value), do: value

  defp print({:object, []}, _indent), do: "{}"

  defp print({:object, members}, indent) do
    inner = indent <> "  "

    body =
      Enum.map_intersperse(members, ",\n", fn {k, v} ->
        [inner, JSON.encode!(k), ": ", print(v, inner)]
      end)

    ["{\n", body, ?\n, indent, ?}]
  end

  defp print([], _indent), do: "[]"

  defp print(list, indent) when is_list(list) do
    inner = indent <> "  "
    ["[\n", Enum.map_intersperse(list, ",\n", &[inner, print(&1, inner)]), ?\n, indent, ?]]
  end

  defp print(value, _indent), do: JSON.encode!(value)
end
