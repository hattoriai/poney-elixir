defmodule Poney.Schema do
  @moduledoc false

  # The shape check (§9.1), read from the published JSON Schema itself,
  # priv/spec/poney.schema.json (draft-07). This module interprets the
  # keywords that schema uses, and fails to compile when a new schema uses
  # one it does not know, so the check never silently weakens. In one walk
  # it reports every value that does not fit, with the specification's
  # paths, and fills in the defaults: the result is the canonical form's
  # shape.
  #
  # A union (anyOf) picks its branch the way the format is written: objects
  # by the member every branch fixes ("type" for views and steps, "kind" for
  # behaviors), other values by their JSON type, then by trying each
  # branch. So a view with a wrong field gets that field's error, not
  # "matches none of ten forms".

  alias Poney.Issue
  alias Poney.Schema.Keywords

  @source Path.expand("../../priv/spec/poney.schema.json", __DIR__)
  @external_resource @source
  @schema @source |> File.read!() |> JSON.decode!()

  @known ~w(type $ref properties required additionalProperties items enum const anyOf
            minItems minLength minimum exclusiveMinimum pattern default
            description title $schema $id definitions)

  for {path, keyword} <- Keywords.unknown(@schema, @known) do
    raise CompileError,
      description:
        "#{@source} uses the JSON Schema keyword #{inspect(keyword)} at #{path}, " <>
          "which Poney.Schema does not interpret yet"
  end

  @version get_in(@schema, ["definitions", "PoneyDocument", "properties", "poneyVersion", "const"])

  @doc "The format version this schema describes."
  @spec version() :: String.t()
  def version, do: @version

  @doc "The schema, as published."
  @spec schema() :: map()
  def schema, do: @schema

  @doc """
  Checks a decoded JSON value against the schema. Returns the value with
  every default filled in, and the problems found, in document order.
  """
  @spec check(term()) :: {term(), [Issue.t()]}
  def check(value) do
    {value, issues} = walk(value, @schema, [])
    {value, Enum.reverse(issues)}
  end

  # ── The walk ────────────────────────────────────────────────────────────
  # Issues collect in reverse, so each step only prepends.

  defp walk(value, %{"$ref" => ref}, path), do: walk(value, resolve(ref), path)

  defp walk(value, %{"anyOf" => branches}, path),
    do: union(value, Enum.map(branches, &deref/1), path)

  defp walk(value, schema, path) do
    case check_type(value, schema["type"]) do
      :ok -> check_value(value, schema, path)
      {:error, message} -> {value, [Issue.error(Issue.path(path), message) | []]}
    end
  end

  defp check_value(value, schema, path) when is_map(value), do: object(value, schema, path)
  defp check_value(value, schema, path) when is_list(value), do: array(value, schema, path)
  defp check_value(value, schema, path), do: {value, scalar(value, schema, path)}

  defp object(map, schema, path) do
    properties = Map.get(schema, "properties", %{})
    required = Map.get(schema, "required", [])
    extra = map |> Map.keys() |> Enum.reject(&Map.has_key?(properties, &1)) |> Enum.sort()

    {map, []}
    |> then(
      &Enum.reduce(properties, &1, fn property, acc -> member(property, acc, required, path) end)
    )
    |> others(extra, Map.get(schema, "additionalProperties", true), path)
  end

  # A member the schema names: checked when present; when missing, its
  # default, or an error when it is required.
  defp member({key, sub}, {map, issues}, required, path) do
    case {Map.fetch(map, key), default(sub)} do
      {{:ok, value}, _} -> put_member(map, issues, key, value, sub, path)
      {:error, {:ok, default}} -> put_member(map, issues, key, default, sub, path)
      {:error, :none} -> {map, missing(key, key in required, path) ++ issues}
    end
  end

  defp put_member(map, issues, key, value, sub, path) do
    {value, found} = walk(value, sub, path ++ [key])
    {Map.put(map, key, value), found ++ issues}
  end

  defp missing(key, true, path),
    do: [Issue.error(Issue.path(path ++ [key]), "Required", ~s(Add "#{key}".))]

  defp missing(_key, false, _path), do: []

  # Members the schema does not name: refused, checked against one schema
  # (a map from names to values), or open.
  defp others({map, issues}, extra, false, path) do
    found =
      for key <- Enum.reverse(extra) do
        Issue.error(
          Issue.path(path ++ [key]),
          ~s(Unknown member "#{key}"),
          ~s(Remove "#{key}": this place has no such member.)
        )
      end

    {map, found ++ issues}
  end

  defp others(acc, extra, sub, path) when is_map(sub) and map_size(sub) > 0 do
    Enum.reduce(extra, acc, fn key, {map, issues} ->
      put_member(map, issues, key, Map.fetch!(map, key), sub, path)
    end)
  end

  defp others(acc, _extra, _open, _path), do: acc

  defp array(list, schema, path) do
    issues =
      case schema do
        %{"minItems" => min} when length(list) < min ->
          [
            Issue.error(
              Issue.path(path),
              "Needs at least #{min} #{if min == 1, do: "item", else: "items"}"
            )
          ]

        _ ->
          []
      end

    case schema do
      %{"items" => items} ->
        {list, found} =
          list
          |> Enum.with_index()
          |> Enum.map_reduce([], fn {item, i}, acc ->
            {item, found} = walk(item, items, path ++ [i])
            {item, found ++ acc}
          end)

        {list, found ++ issues}

      _ ->
        {list, issues}
    end
  end

  defp scalar(value, schema, path) do
    at = Issue.path(path)

    Enum.flat_map(schema, fn
      {"const", const} when value != const ->
        [Issue.error(at, "Must be #{JSON.encode!(const)}")]

      {"enum", options} ->
        if value in options,
          do: [],
          else: [
            Issue.error(
              at,
              "Unknown value #{JSON.encode!(value)}",
              "Use one of: #{Enum.join(options, ", ")}."
            )
          ]

      {"pattern", pattern} when is_binary(value) ->
        if Regex.match?(regex(pattern), value), do: [], else: [pattern_issue(at, value, pattern)]

      {"minLength", min} when is_binary(value) ->
        if String.length(value) >= min, do: [], else: [Issue.error(at, "Must not be empty")]

      {"minimum", min} when is_number(value) and value < min ->
        [Issue.error(at, "Must be #{min} or more")]

      {"exclusiveMinimum", min} when is_number(value) and value <= min ->
        [Issue.error(at, "Must be more than #{min}")]

      _ ->
        []
    end)
  end

  @id_pattern "^[a-z0-9][a-z0-9-_.]*$"

  defp pattern_issue(at, value, @id_pattern) do
    Issue.error(
      at,
      ~s("#{value}" is not an identifier),
      ~s(Identifiers use lowercase letters, digits, "-", "_" and ".", and start with a letter or digit, e.g. "order-service".)
    )
  end

  defp pattern_issue(at, value, pattern),
    do: Issue.error(at, ~s("#{value}" does not match #{pattern}))

  # ── Unions ──────────────────────────────────────────────────────────────

  defp union(value, branches, path) do
    case Enum.filter(
           branches,
           &(check_type(value, &1["type"]) == :ok or Map.has_key?(&1, "anyOf"))
         ) do
      [] ->
        types =
          branches |> Enum.flat_map(&List.wrap(&1["type"])) |> Enum.uniq() |> Enum.join(" or ")

        {value,
         [Issue.error(Issue.path(path), "Expected #{types}, received #{type_name(value)}")]}

      [one] ->
        walk(value, one, path)

      candidates when is_map(value) ->
        case discriminator(candidates) do
          nil -> first_fit(value, candidates, path)
          key -> by_discriminator(value, candidates, key, path)
        end

      candidates ->
        first_fit(value, candidates, path)
    end
  end

  # The member that every object branch fixes to a different constant.
  defp discriminator(branches) do
    keys =
      Enum.map(branches, fn b ->
        b
        |> Map.get("properties", %{})
        |> Enum.filter(fn {_, s} -> Map.has_key?(deref(s), "const") end)
        |> Enum.map(&elem(&1, 0))
        |> MapSet.new()
      end)

    case keys do
      [first | rest] -> keys_in_all(first, rest)
      [] -> nil
    end
  end

  defp keys_in_all(first, rest) do
    rest |> Enum.reduce(first, &MapSet.intersection/2) |> Enum.sort() |> List.first()
  end

  defp by_discriminator(value, branches, key, path) do
    consts =
      Enum.map(branches, &(&1 |> get_in(["properties", key]) |> deref() |> Map.fetch!("const")))

    case Enum.find_index(consts, &(&1 == value[key])) do
      nil when is_map_key(value, key) ->
        {value,
         [
           Issue.error(
             Issue.path(path ++ [key]),
             "Unknown #{key} #{JSON.encode!(value[key])}",
             "Use one of: #{Enum.join(consts, ", ")}."
           )
         ]}

      nil ->
        {value,
         [
           Issue.error(
             Issue.path(path ++ [key]),
             "Required",
             ~s|Add "#{key}": one of #{Enum.join(consts, ", ")}.|
           )
         ]}

      i ->
        walk(value, Enum.at(branches, i), path)
    end
  end

  # Values a union cannot tell apart by type: the first branch they fit.
  defp first_fit(value, branches, path) do
    Enum.find_value(branches, fn branch ->
      case walk(value, branch, path) do
        {value, []} -> {value, []}
        _ -> nil
      end
    end) || {value, [no_fit(value, branches, path)]}
  end

  defp no_fit(value, branches, path) do
    forms =
      Enum.flat_map(branches, fn
        %{"enum" => options} -> [Enum.join(options, ", ")]
        %{"pattern" => pattern} -> ["a value that matches #{pattern}"]
        _ -> []
      end)

    hint = if forms == [], do: nil, else: "Use one of: #{Enum.join(forms, ", or ")}."
    Issue.error(Issue.path(path), "#{JSON.encode!(value)} is not allowed here", hint)
  end

  # ── Types, references and defaults ──────────────────────────────────────

  defp check_type(_value, nil), do: :ok

  defp check_type(value, types) when is_list(types) do
    if Enum.any?(types, &(check_type(value, &1) == :ok)),
      do: :ok,
      else: {:error, "Expected #{Enum.join(types, " or ")}, received #{type_name(value)}"}
  end

  defp check_type(value, type) do
    if type?(value, type),
      do: :ok,
      else: {:error, "Expected #{type}, received #{type_name(value)}"}
  end

  defp type?(value, "object"), do: is_map(value)
  defp type?(value, "array"), do: is_list(value)
  defp type?(value, "string"), do: is_binary(value)
  defp type?(value, "boolean"), do: is_boolean(value)
  defp type?(value, "null"), do: is_nil(value)
  defp type?(value, "number"), do: is_number(value)
  # JSON has one number type: 2.0 is an integer, as in JavaScript.
  defp type?(value, "integer"),
    do: is_integer(value) or (is_float(value) and value == trunc(value))

  defp type_name(value) when is_map(value), do: "object"
  defp type_name(value) when is_list(value), do: "array"
  defp type_name(value) when is_binary(value), do: "string"
  defp type_name(value) when is_boolean(value), do: "boolean"
  defp type_name(nil), do: "null"
  defp type_name(value) when is_number(value), do: "number"

  defp default(%{"default" => default}), do: {:ok, default}
  defp default(%{"$ref" => ref}), do: default(resolve(ref))
  defp default(_), do: :none

  defp deref(%{"$ref" => ref}), do: deref(resolve(ref))
  defp deref(schema), do: schema

  # A JSON Pointer into this schema: "#/definitions/PoneyDocument/…".
  defp resolve("#" <> pointer) do
    pointer
    |> String.split("/", trim: true)
    |> Enum.reduce(@schema, fn segment, node ->
      segment = segment |> String.replace("~1", "/") |> String.replace("~0", "~")

      case node do
        list when is_list(list) -> Enum.at(list, String.to_integer(segment))
        map -> Map.fetch!(map, segment)
      end
    end)
  end

  # Regexes compile once per pattern. "$" matches only at the very end, as
  # in JavaScript, not before a final newline.
  defp regex(pattern) do
    key = {__MODULE__, :regex, pattern}

    case :persistent_term.get(key, nil) do
      nil ->
        regex = Regex.compile!(pattern, [:unicode, :dollar_endonly])
        :persistent_term.put(key, regex)
        regex

      regex ->
        regex
    end
  end
end
