defmodule Poney.SchemaTest do
  # Poney.Schema reads the published JSON Schema with its own small
  # interpreter. A full validator (JSV) is the reference: on any change to a
  # real document, both must agree on whether the shape fits.
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Poney.{Fixtures, Schema}
  alias Poney.Schema.Keywords

  @base Fixtures.example("kestrel-commerce")

  defp paths(value, at \\ [])

  defp paths(map, at) when is_map(map),
    do: Enum.flat_map(map, fn {k, v} -> [at ++ [k] | paths(v, at ++ [k])] end)

  defp paths(list, at) when is_list(list),
    do:
      list
      |> Enum.with_index()
      |> Enum.flat_map(fn {v, i} -> [at ++ [i] | paths(v, at ++ [i])] end)

  defp paths(_value, _at), do: []

  defp change(doc, path, op), do: update(doc, path, op)

  defp update(container, [key], op), do: apply_op(container, key, op)

  defp update(map, [key | rest], op) when is_map(map),
    do: Map.update!(map, key, &update(&1, rest, op))

  defp update(list, [i | rest], op) when is_list(list),
    do: List.update_at(list, i, &update(&1, rest, op))

  defp apply_op(map, key, :delete) when is_map(map), do: Map.delete(map, key)
  defp apply_op(list, i, :delete) when is_list(list), do: List.delete_at(list, i)
  defp apply_op(map, key, {:set, value}) when is_map(map), do: Map.put(map, key, value)
  defp apply_op(list, i, {:set, value}) when is_list(list), do: List.replace_at(list, i, value)

  defp apply_op(map, key, :unknown_member) when is_map(map),
    do: Map.update!(map, key, &add_member/1)

  defp apply_op(list, i, :unknown_member) when is_list(list),
    do: List.update_at(list, i, &add_member/1)

  defp add_member(map) when is_map(map), do: Map.put(map, "colour", "red")
  defp add_member(other), do: other

  defp ops do
    one_of([
      constant(:delete),
      constant(:unknown_member),
      map(member_of([42, true, "Not An Id", [], %{}, nil, "zz"]), &{:set, &1})
    ])
  end

  property "agrees with a full JSON Schema validator on any change to a real document" do
    all = paths(@base)

    check all(path <- member_of(all), op <- ops(), max_runs: 400) do
      doc = change(@base, path, op)
      {canonical, issues} = Schema.check(doc)
      jsv = JSV.validate(doc, Fixtures.jsv())

      assert issues == [] == match?({:ok, _}, jsv),
             "#{inspect(path)} #{inspect(op)}: Poney.Schema #{inspect(Enum.map(issues, &to_string/1))}, JSV #{elem(jsv, 0)}"

      # Filling in the defaults keeps a valid document valid.
      if issues == [], do: assert({:ok, _} = JSV.validate(canonical, Fixtures.jsv()))
    end
  end

  test "knows every keyword of the published schema" do
    assert Keywords.unknown(
             Schema.schema(),
             ~w(type $ref properties required additionalProperties items enum const anyOf
             minItems minLength minimum exclusiveMinimum pattern default description title $schema $id definitions)
           ) == []

    assert [{"#/properties/a", "uniqueItems"}] =
             Keywords.unknown(
               %{"properties" => %{"a" => %{"uniqueItems" => true}}},
               ~w(properties)
             )
  end

  test "an identifier with a final newline is not an identifier, as in JavaScript" do
    doc = put_in(@base, ["project", "id"], "kestrel\n")
    assert [%{path: "project.id"}] = elem(Schema.check(doc), 1)
  end
end
