defmodule Poney.Upgrade do
  @moduledoc false

  # Brings a document written for an earlier version of the format to the
  # current one (§11): a reader must open a 0.1.0 document as it is.
  #
  # 0.1.0 → 0.2.0, the names that follow the industry's terms:
  #   * entity kinds "module" → "component" (C4), "queue" → "message-broker",
  #     with their styles; the old default labels are renamed too;
  #   * data relation ends (crow's foot) "one" → "exactly-one",
  #     "many" → "zero-or-many";
  #   * use cases (UML): model.capabilities → model.useCases, the use case
  #     view's "capabilities" → "useCases", refs "capability:…" → "useCase:…";
  #   * activities (UML): behavior kind "process" → "activity", the activity
  #     view's "process" → "activity", nodes "start"/"end" → "initial"/"final";
  #   * states: kind "normal" → "state";
  #   * the tone "poney" → "accent", the view category "capabilities" →
  #     "use-cases".

  @entity_kinds %{"module" => "component", "queue" => "message-broker"}
  @old_labels %{"module" => {"Module", "Component"}, "queue" => {"Event bus", "Message broker"}}
  @cardinalities %{"one" => "exactly-one", "many" => "zero-or-many"}

  @doc "The document in the current version: unchanged when it is current, or not a 0.1.0 document."
  @spec upgrade(term()) :: term()
  def upgrade(%{"poneyVersion" => "0.1.0"} = doc) do
    doc
    |> Map.put("poneyVersion", "0.2.0")
    |> update_model()
    |> update_presentation()
    |> update_views()
    |> rename_deep(nil)
  end

  def upgrade(doc), do: doc

  defp update_model(%{"model" => model} = doc) when is_map(model) do
    model =
      model
      |> update_list("entities", fn e ->
        update_string(e, "kind", &Map.get(@entity_kinds, &1, &1))
      end)
      |> update_list("dataRelations", fn r ->
        Enum.reduce(["fromCardinality", "toCardinality"], r, fn end_, r ->
          update_string(r, end_, &Map.get(@cardinalities, &1, &1))
        end)
      end)
      |> rename_key("capabilities", "useCases")
      |> update_list("behaviors", &update_behavior/1)

    Map.put(doc, "model", model)
  end

  defp update_model(doc), do: doc

  defp update_behavior(%{"kind" => "process"} = b) do
    nodes = fn n ->
      update_string(n, "kind", &Map.get(%{"start" => "initial", "end" => "final"}, &1, &1))
    end

    b |> Map.put("kind", "activity") |> update_list("nodes", nodes)
  end

  defp update_behavior(%{"kind" => "state-machine"} = b) do
    update_list(b, "states", fn s ->
      update_string(s, "kind", &if(&1 == "normal", do: "state", else: &1))
    end)
  end

  defp update_behavior(b), do: b

  defp update_presentation(%{"presentation" => %{"kinds" => kinds} = p} = doc)
       when is_map(kinds) do
    kinds = Enum.reduce(@entity_kinds, kinds, &rename_kind/2)
    Map.put(doc, "presentation", Map.put(p, "kinds", kinds))
  end

  defp update_presentation(doc), do: doc

  # A kind's style moves to its new name; its old default label too.
  defp rename_kind({from, to}, kinds) do
    case Map.fetch(kinds, from) do
      {:ok, style} -> kinds |> Map.delete(from) |> Map.put(to, relabel(style, @old_labels[from]))
      :error -> kinds
    end
  end

  defp relabel(%{"label" => old} = style, {old, new}), do: Map.put(style, "label", new)
  defp relabel(style, _labels), do: style

  # Views, also those written inside walkthrough scenes.
  defp update_views(doc) do
    doc
    |> update_list("views", &update_view/1)
    |> update_list("walkthroughs", fn w ->
      w
      |> update_map("overview", &update_view/1)
      |> update_list("scenes", fn s -> update_map(s, "view", &update_view/1) end)
    end)
  end

  defp update_view(view) do
    view =
      case view do
        %{"type" => "usecase"} -> rename_key(view, "capabilities", "useCases")
        %{"type" => "activity"} -> rename_key(view, "process", "activity")
        _ -> view
      end

    if view["category"] == "capabilities", do: Map.put(view, "category", "use-cases"), else: view
  end

  # Everywhere: refs "capability:…" become "useCase:…", and the tone "poney" becomes "accent".
  defp rename_deep("capability:" <> rest, _key), do: "useCase:" <> rest
  defp rename_deep("poney", "tone"), do: "accent"
  defp rename_deep(list, key) when is_list(list), do: Enum.map(list, &rename_deep(&1, key))

  defp rename_deep(map, _key) when is_map(map),
    do: Map.new(map, fn {k, v} -> {k, rename_deep(v, k)} end)

  defp rename_deep(value, _key), do: value

  defp update_list(map, key, fun) do
    case map do
      %{^key => list} when is_list(list) ->
        Map.put(map, key, Enum.map(list, &update_item(&1, fun)))

      _ ->
        map
    end
  end

  defp update_item(item, fun) when is_map(item), do: fun.(item)
  defp update_item(item, _fun), do: item

  defp update_map(map, key, fun) do
    case map do
      %{^key => value} when is_map(value) -> Map.put(map, key, fun.(value))
      _ -> map
    end
  end

  defp update_string(map, key, fun) do
    case map do
      %{^key => value} when is_binary(value) -> Map.put(map, key, fun.(value))
      _ -> map
    end
  end

  defp rename_key(map, from, to) do
    case Map.fetch(map, from) do
      {:ok, value} -> map |> Map.delete(from) |> Map.put(to, value)
      :error -> map
    end
  end
end
