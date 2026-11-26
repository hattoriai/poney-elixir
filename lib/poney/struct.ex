defmodule Poney.Struct do
  @moduledoc false

  # The structs of a document, from its canonical JSON. A struct module
  # lists its members once:
  #
  #     use Poney.Struct,
  #       fields: [id: :value, source_refs: {:list, Poney.Model.SourceRef}]
  #
  # Each field reads the JSON member of the same name in camel case
  # ("sourceRefs"), or the name given as `{"json name", type}`. Types:
  #
  #   * `:value` — the JSON value as it is (strings, numbers, booleans,
  #     lists of them, and maps such as `ext` that the format leaves open);
  #   * a module — a struct, from a JSON object;
  #   * `{:list, type}` and `{:map, type}` — a list, or a map from strings,
  #     of that type.
  #
  # A union (a view, a behavior, a step) is a module whose from_json/1
  # picks the struct by the member that names its form.
  #
  # `nil` stays `nil`: in the canonical form, only optional members are
  # missing.

  defmacro __using__(opts) do
    fields = Keyword.fetch!(opts, :fields)

    quote bind_quoted: [fields: fields] do
      @poney_fields Enum.map(fields, fn
                      {name, {json, type}} when is_binary(json) -> {name, json, type}
                      {name, type} -> {name, Poney.Struct.camel(name), type}
                    end)

      defstruct Enum.map(@poney_fields, &elem(&1, 0))

      @doc false
      @spec fields() :: [{atom(), String.t(), term()}]
      def fields, do: @poney_fields

      @doc false
      @spec from_json(map()) :: t()
      def from_json(json) when is_map(json) do
        struct!(
          __MODULE__,
          Enum.map(@poney_fields, fn {name, key, type} ->
            {name, Poney.Struct.cast(json[key], type)}
          end)
        )
      end
    end
  end

  @doc false
  @spec camel(atom()) :: String.t()
  def camel(name) do
    [first | rest] = name |> Atom.to_string() |> String.split("_")
    Enum.join([first | Enum.map(rest, &String.capitalize/1)])
  end

  @doc false
  @spec cast(term(), term()) :: term()
  def cast(nil, _type), do: nil
  def cast(value, :value), do: value
  def cast(list, {:list, type}), do: Enum.map(list, &cast(&1, type))
  def cast(map, {:map, type}), do: Map.new(map, fn {k, v} -> {k, cast(v, type)} end)
  def cast(json, module) when is_atom(module), do: module.from_json(json)
end
