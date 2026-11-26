defmodule Poney.Rules do
  @moduledoc false

  # The rules JSON Schema cannot say (§9.2, §8.4), on a canonical document:
  # identifiers are unique, every reference names something that exists,
  # behaviors are well formed, walkthroughs point at real elements, and
  # extensions are declared. Errors make the document invalid; W1 and
  # unknown optional extensions are warnings.
  #
  # This reader knows no extension: a required one makes the document
  # invalid, an optional one is kept and reported (§8.4).

  alias Poney.{Issue, Ref}

  @core_entity_kinds ~w(person system web-app service gateway database cache message-broker
                        external component interface library)
  @core_relationship_kinds ~w(uses calls reads writes reads-writes publishes subscribes
                              depends-on implements)

  @spec check(map()) :: [Issue.t()]
  def check(doc) do
    index = index(doc)

    [
      &unique/2,
      &entities/2,
      &relationships/2,
      &data_types/2,
      &data_relations/2,
      &data_flows/2,
      &behaviors/2,
      &use_cases/2,
      &views/2,
      &walkthroughs/2,
      &default_view/2,
      &styles/2,
      &extensions/2
    ]
    |> Enum.flat_map(& &1.(doc, index))
  end

  # ── Index ───────────────────────────────────────────────────────────────

  defp index(doc) do
    m = doc["model"]
    by_id = &Map.new(&1, fn item -> {item["id"], item} end)

    %{
      entities: by_id.(m["entities"]),
      relationships: by_id.(m["relationships"]),
      data_types: by_id.(m["dataTypes"]),
      data_relations: by_id.(m["dataRelations"]),
      data_flows: by_id.(m["dataFlows"]),
      behaviors: by_id.(m["behaviors"]),
      use_cases: by_id.(m["useCases"]),
      views: by_id.(doc["views"])
    }
  end

  # Every message of an interaction, in fragments too.
  defp messages(steps) do
    Enum.flat_map(steps, fn
      %{"type" => "message"} = m ->
        [m]

      %{"type" => "fragment", "branches" => branches} ->
        Enum.flat_map(branches, &messages(&1["steps"]))
    end)
  end

  defp fragments(steps) do
    Enum.flat_map(steps, fn
      %{"type" => "fragment", "branches" => branches} = f ->
        [f | Enum.flat_map(branches, &fragments(&1["steps"]))]

      _ ->
        []
    end)
  end

  defp behavior(index, id, kind) do
    case index.behaviors[id] do
      %{"kind" => ^kind} = b -> b
      _ -> nil
    end
  end

  # True when a ref names an element of the document.
  defp exists?(%Ref{kind: :entity, id: id}, i), do: Map.has_key?(i.entities, id)
  defp exists?(%Ref{kind: :relationship, id: id}, i), do: Map.has_key?(i.relationships, id)
  defp exists?(%Ref{kind: :data_relation, id: id}, i), do: Map.has_key?(i.data_relations, id)
  defp exists?(%Ref{kind: :data_flow, id: id}, i), do: Map.has_key?(i.data_flows, id)
  defp exists?(%Ref{kind: :use_case, id: id}, i), do: Map.has_key?(i.use_cases, id)
  defp exists?(%Ref{kind: :behavior, id: id}, i), do: Map.has_key?(i.behaviors, id)

  defp exists?(%Ref{kind: :data_type, id: id, field: field}, i) do
    case i.data_types[id] do
      nil -> false
      d -> is_nil(field) or Enum.any?(d["fields"], &(&1["name"] == field))
    end
  end

  defp exists?(%Ref{kind: :message, behavior: b, id: id}, i),
    do: in_interaction?(i, b, id, &messages/1)

  defp exists?(%Ref{kind: :fragment, behavior: b, id: id}, i),
    do: in_interaction?(i, b, id, &fragments/1)

  defp exists?(%Ref{kind: :activity_node, behavior: b, id: id}, i),
    do: has_id?(behavior(i, b, "activity"), "nodes", id)

  defp exists?(%Ref{kind: :activity_flow, behavior: b, id: id}, i),
    do: has_id?(behavior(i, b, "activity"), "flows", id)

  defp exists?(%Ref{kind: :state, behavior: b, id: id}, i),
    do: has_id?(behavior(i, b, "state-machine"), "states", id)

  defp exists?(%Ref{kind: :transition, behavior: b, id: id}, i),
    do: has_id?(behavior(i, b, "state-machine"), "transitions", id)

  defp exists?(%Ref{kind: :group, view: v, id: id}, i) do
    case i.views[v] do
      %{"type" => "architecture", "groups" => groups} -> Enum.any?(groups, &(&1["id"] == id))
      %{"type" => "dependency", "layers" => layers} -> Enum.any?(layers, &(&1["id"] == id))
      _ -> false
    end
  end

  defp in_interaction?(index, b, id, steps_of) do
    case behavior(index, b, "interaction") do
      nil -> false
      interaction -> interaction["steps"] |> steps_of.() |> Enum.any?(&(&1["id"] == id))
    end
  end

  defp has_id?(nil, _key, _id), do: false
  defp has_id?(behavior, key, id), do: Enum.any?(behavior[key], &(&1["id"] == id))

  # ── R1: identifiers are unique ──────────────────────────────────────────

  @collections [
    {["model", "entities"]},
    {["model", "relationships"]},
    {["model", "dataTypes"]},
    {["model", "dataRelations"]},
    {["model", "dataFlows"]},
    {["model", "behaviors"]},
    {["model", "useCases"]},
    {["views"]}
  ]

  defp unique(doc, _index) do
    Enum.flat_map(@collections, fn {path} -> duplicates(get_in(doc, path), path) end)
  end

  defp duplicates(items, path) do
    items
    |> Enum.with_index()
    |> Enum.reduce({MapSet.new(), []}, fn {item, i}, {seen, issues} ->
      id = item["id"]

      if MapSet.member?(seen, id),
        do:
          {seen, [Issue.error(Issue.path(path ++ [i, "id"]), ~s(Duplicate id "#{id}")) | issues]},
        else: {MapSet.put(seen, id), issues}
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  # ── References into the model ───────────────────────────────────────────

  defp entity(index, id, path) do
    if is_nil(id) or Map.has_key?(index.entities, id),
      do: [],
      else: [unknown(path, "entity", id, Map.keys(index.entities), "entity to model.entities")]
  end

  defp data_type(index, id, path) do
    if is_nil(id) or Map.has_key?(index.data_types, id),
      do: [],
      else: [
        unknown(path, "data type", id, Map.keys(index.data_types), "data type to model.dataTypes")
      ]
  end

  defp relationship(index, id, path) do
    if is_nil(id) or Map.has_key?(index.relationships, id),
      do: [],
      else: [
        unknown(
          path,
          "relationship",
          id,
          Map.keys(index.relationships),
          "relationship to model.relationships"
        )
      ]
  end

  defp unknown(path, what, id, candidates, add) do
    Issue.error(Issue.path(path), ~s(Unknown #{what} "#{id}"), did_you_mean(id, candidates, add))
  end

  defp each(list, path, fun) do
    list |> Enum.with_index() |> Enum.flat_map(fn {item, i} -> fun.(item, path ++ [i]) end)
  end

  # ── R2: entities ────────────────────────────────────────────────────────

  defp entities(doc, index) do
    each(doc["model"]["entities"], ["model", "entities"], fn e, path ->
      entity(index, e["parent"], path ++ ["parent"]) ++ cycle(e, index, path)
    end)
  end

  defp cycle(e, index, path),
    do: climb(index.entities[e["parent"]], MapSet.new([e["id"]]), index, path)

  defp climb(nil, _seen, _index, _path), do: []

  defp climb(cursor, seen, index, path) do
    if MapSet.member?(seen, cursor["id"]),
      do: [
        Issue.error(
          Issue.path(path ++ ["parent"]),
          ~s(Containment cycle through "#{cursor["id"]}")
        )
      ],
      else: climb(index.entities[cursor["parent"]], MapSet.put(seen, cursor["id"]), index, path)
  end

  # ── R3–R6: relationships and data ───────────────────────────────────────

  defp relationships(doc, index) do
    each(doc["model"]["relationships"], ["model", "relationships"], fn r, path ->
      entity(index, r["source"], path ++ ["source"]) ++
        entity(index, r["target"], path ++ ["target"]) ++
        each(r["data"], path ++ ["data"], &data_type(index, &1, &2))
    end)
  end

  defp data_types(doc, index) do
    each(doc["model"]["dataTypes"], ["model", "dataTypes"], fn t, path ->
      entity(index, t["ownedBy"], path ++ ["ownedBy"]) ++
        entity(index, t["storedIn"], path ++ ["storedIn"]) ++ fields(t, index, path)
    end)
  end

  defp fields(t, index, path) do
    t["fields"]
    |> Enum.with_index()
    |> Enum.reduce({MapSet.new(), []}, fn {f, j}, {names, issues} ->
      at = path ++ ["fields", j]

      duplicate =
        if MapSet.member?(names, f["name"]),
          do: [Issue.error(Issue.path(at), ~s(Duplicate field "#{f["name"]}" in "#{t["id"]}"))],
          else: []

      {MapSet.put(names, f["name"]),
       issues ++ duplicate ++ foreign_key(f["references"], index, at)}
    end)
    |> elem(1)
  end

  defp foreign_key(nil, _index, _path), do: []

  defp foreign_key(%{"dataType" => type, "field" => field}, index, path) do
    case index.data_types[type] do
      nil ->
        [Issue.error(Issue.path(path ++ ["references"]), ~s(Unknown data type "#{type}"))]

      target ->
        if Enum.any?(target["fields"], &(&1["name"] == field)),
          do: [],
          else: [
            Issue.error(Issue.path(path ++ ["references"]), ~s("#{type}" has no field "#{field}"))
          ]
    end
  end

  defp data_relations(doc, index) do
    each(doc["model"]["dataRelations"], ["model", "dataRelations"], fn r, path ->
      via =
        with via when via not in [nil, ""] <- r["via"],
             false <- Enum.any?([r["from"], r["to"]], &has_field?(index, &1, via)) do
          [Issue.error(Issue.path(path ++ ["via"]), ~s(Neither end has field "#{via}"))]
        else
          _ -> []
        end

      data_type(index, r["from"], path ++ ["from"]) ++
        data_type(index, r["to"], path ++ ["to"]) ++ via
    end)
  end

  defp has_field?(index, type, field) do
    case index.data_types[type] do
      nil -> false
      t -> Enum.any?(t["fields"], &(&1["name"] == field))
    end
  end

  defp data_flows(doc, index) do
    each(doc["model"]["dataFlows"], ["model", "dataFlows"], fn f, path ->
      entity(index, f["source"], path ++ ["source"]) ++
        entity(index, f["target"], path ++ ["target"]) ++
        relationship(index, f["via"], path ++ ["via"]) ++
        each(f["data"], path ++ ["data"], &data_type(index, &1, &2))
    end)
  end

  # ── R7–R9: behaviors ────────────────────────────────────────────────────

  defp behaviors(doc, index) do
    each(doc["model"]["behaviors"], ["model", "behaviors"], fn b, path ->
      behavior_rules(b, index, path)
    end)
  end

  defp behavior_rules(%{"kind" => "interaction"} = b, index, path) do
    participants = b["participants"]

    party = {MapSet.new(participants), Enum.join(participants, ", ")}
    {issues, _ids} = steps(b["steps"], path ++ ["steps"], party, index, MapSet.new())

    each(participants, path ++ ["participants"], &entity(index, &1, &2)) ++ issues
  end

  defp behavior_rules(%{"kind" => "activity"} = b, index, path) do
    nodes = MapSet.new(b["nodes"], & &1["id"])

    duplicates(b["nodes"], path ++ ["nodes"]) ++
      each(
        b["nodes"],
        path ++ ["nodes"],
        &entity(index, &1["performedBy"], &2 ++ ["performedBy"])
      ) ++
      exactly_one_initial(b["nodes"], path ++ ["nodes"], "A process needs exactly one start node") ++
      each(b["flows"], path ++ ["flows"], fn f, at ->
        ends(f, nodes, at, "node")
      end)
  end

  defp behavior_rules(%{"kind" => "state-machine"} = b, index, path) do
    states = MapSet.new(b["states"], & &1["id"])

    data_type(index, b["subject"], path ++ ["subject"]) ++
      entity(index, b["owner"], path ++ ["owner"]) ++
      duplicates(b["states"], path ++ ["states"]) ++
      exactly_one_initial(
        b["states"],
        path ++ ["states"],
        "A state machine needs exactly one initial state"
      ) ++
      each(b["transitions"], path ++ ["transitions"], fn t, at ->
        ends(t, states, at, "state") ++ entity(index, t["triggeredBy"], at ++ ["triggeredBy"])
      end)
  end

  defp exactly_one_initial(items, path, message) do
    if Enum.count(items, &(&1["kind"] == "initial")) == 1,
      do: [],
      else: [Issue.error(Issue.path(path), message)]
  end

  defp ends(link, ids, path, what) do
    for end_ <- ["from", "to"], not MapSet.member?(ids, link[end_]) do
      id = link[end_]

      Issue.error(
        Issue.path(path ++ [end_]),
        ~s(Unknown #{what} "#{id}"),
        did_you_mean(id, ids, what)
      )
    end
  end

  # Steps in order, fragments within: ids are unique in the interaction,
  # and messages go between its participants (R7).
  defp steps(list, path, participants, index, ids) do
    list
    |> Enum.with_index()
    |> Enum.reduce({[], ids}, fn {s, j}, {issues, ids} ->
      at = path ++ [j]

      duplicate =
        if MapSet.member?(ids, s["id"]),
          do: [Issue.error(Issue.path(at ++ ["id"]), ~s(Duplicate step id "#{s["id"]}"))],
          else: []

      {found, ids} = step(s, at, participants, index, MapSet.put(ids, s["id"]))
      {issues ++ duplicate ++ found, ids}
    end)
  end

  defp step(%{"type" => "message"} = m, path, {participants, listed}, index, ids) do
    party =
      for {end_, verb} <- [{"from", "send from"}, {"to", "send to"}],
          not MapSet.member?(participants, m[end_]) do
        id = m[end_]

        Issue.error(
          Issue.path(path ++ [end_]),
          ~s("#{id}" is not a participant),
          ~s(Add "#{id}" to participants, or #{verb} one of: #{listed}.)
        )
      end

    {party ++
       relationship(index, m["relationship"], path ++ ["relationship"]) ++
       each(m["data"], path ++ ["data"], &data_type(index, &1, &2)), ids}
  end

  defp step(%{"type" => "fragment"} = f, path, participants, index, ids) do
    f["branches"]
    |> Enum.with_index()
    |> Enum.reduce({[], ids}, fn {branch, k}, {issues, ids} ->
      {found, ids} =
        steps(branch["steps"], path ++ ["branches", k, "steps"], participants, index, ids)

      {issues ++ found, ids}
    end)
  end

  # ── R10: use cases ──────────────────────────────────────────────────────

  defp use_cases(doc, index) do
    each(doc["model"]["useCases"], ["model", "useCases"], fn c, path ->
      Enum.flat_map(["actors", "supporting", "realizedBy"], fn key ->
        each(c[key], path ++ [key], &entity(index, &1, &2))
      end) ++
        each(c["behaviors"], path ++ ["behaviors"], &known(index.behaviors, &1, &2, "behavior")) ++
        each(c["includes"], path ++ ["includes"], &known(index.use_cases, &1, &2, "use case"))
    end)
  end

  defp known(map, id, path, what) do
    if Map.has_key?(map, id),
      do: [],
      else: [Issue.error(Issue.path(path), ~s(Unknown #{what} "#{id}"))]
  end

  # ── R11: views ──────────────────────────────────────────────────────────

  defp views(doc, index) do
    each(doc["views"], ["views"], fn v, path -> view(v, doc, index, path) end)
  end

  defp view(%{"type" => type} = v, _doc, index, path)
       when type in ~w(architecture map dependency) do
    shown = MapSet.new(v["entities"])
    {key, groups} = groups(v)

    each(v["entities"], path ++ ["entities"], &entity(index, &1, &2)) ++
      each(v["relationships"] || [], path ++ ["relationships"], &relationship(index, &1, &2)) ++
      members(groups, shown, path ++ [key]) ++ collapsed(v, shown, groups, index, path)
  end

  defp view(%{"type" => "sequence"} = v, _doc, index, path),
    do: behavior_of_kind(index, v["interaction"], "interaction", path ++ ["interaction"])

  defp view(%{"type" => "activity"} = v, _doc, index, path),
    do: behavior_of_kind(index, v["activity"], "activity", path ++ ["activity"])

  defp view(%{"type" => "state"} = v, _doc, index, path),
    do: behavior_of_kind(index, v["stateMachine"], "state-machine", path ++ ["stateMachine"])

  defp view(%{"type" => "erd"} = v, _doc, index, path),
    do: each(v["dataTypes"], path ++ ["dataTypes"], &data_type(index, &1, &2))

  defp view(%{"type" => "dataflow"} = v, _doc, index, path),
    do: each(v["flows"], path ++ ["flows"], &known(index.data_flows, &1, &2, "data flow"))

  defp view(%{"type" => "extension"} = v, _doc, index, path),
    do: each(v["entities"], path ++ ["entities"], &entity(index, &1, &2))

  defp view(%{"type" => "usecase"} = v, _doc, index, path),
    do: each(v["useCases"], path ++ ["useCases"], &known(index.use_cases, &1, &2, "use case"))

  defp groups(%{"type" => "architecture", "groups" => groups}), do: {"groups", groups}
  defp groups(%{"type" => "dependency", "layers" => layers}), do: {"layers", layers}
  defp groups(_map), do: {"groups", []}

  # Groups and layers list only entities that the view shows.
  defp members(groups, shown, path) do
    for {g, j} <- Enum.with_index(groups),
        {member, k} <- Enum.with_index(g["members"]),
        not MapSet.member?(shown, member) do
      Issue.error(Issue.path(path ++ [j, "members", k]), ~s("#{member}" is not in this view))
    end
  end

  defp collapsed(%{"type" => "map"} = v, shown, _groups, index, path) do
    each(v["passThrough"], path ++ ["passThrough"], &entity(index, &1, &2)) ++
      each(v["collapsed"], path ++ ["collapsed"], fn c, at ->
        cond do
          not MapSet.member?(shown, c) ->
            [Issue.error(Issue.path(at), ~s("#{c}" is not in this view))]

          not Enum.any?(v["entities"], &(get_in(index.entities, [&1, "parent"]) == c)) ->
            [
              Issue.error(
                Issue.path(at),
                ~s("#{c}" has nothing inside it in this view),
                ~s|A group is an entity whose children (entities with "parent" set to it) are also in the map.|
              )
            ]

          true ->
            []
        end
      end)
  end

  defp collapsed(%{"type" => "architecture"} = v, shown, groups, _index, path) do
    each(v["collapsed"], path ++ ["collapsed"], fn c, at ->
      if MapSet.member?(shown, c) or Enum.any?(groups, &(&1["id"] == c)),
        do: [],
        else: [Issue.error(Issue.path(at), ~s("#{c}" is not in this view))]
    end)
  end

  defp collapsed(_view, _shown, _groups, _index, _path), do: []

  defp behavior_of_kind(index, id, kind, path) do
    case index.behaviors[id] do
      nil ->
        [Issue.error(Issue.path(path), ~s(Unknown behavior "#{id}"))]

      %{"kind" => ^kind} ->
        []

      %{"kind" => other} ->
        [Issue.error(Issue.path(path), ~s("#{id}" is a #{other}, expected #{kind}))]
    end
  end

  # ── R13, R14: walkthroughs ──────────────────────────────────────────────

  defp walkthroughs(doc, index) do
    each(doc["walkthroughs"], ["walkthroughs"], fn w, path -> walkthrough(w, index, path) end)
  end

  defp walkthrough(w, index, path) do
    removed = w["removed"]
    gone_entities = MapSet.new(removed["entities"], & &1["id"])

    gone =
      MapSet.new(
        Enum.map(removed["entities"], &"entity:#{&1["id"]}") ++
          Enum.map(removed["relationships"], &"relationship:#{&1["id"]}") ++
          Enum.map(
            removed["transitions"],
            &"transition:#{&1["stateMachine"]}:#{&1["transition"]["id"]}"
          )
      )

    known = fn key, at -> known_ref(key, at, index, gone) end

    removed_rules(removed, index, gone_entities, path ++ ["removed"]) ++
      story(w, path) ++
      tour_marks(w, path) ++
      view_ref(w["overview"], index, path ++ ["overview"]) ++
      each(w["marks"], path ++ ["marks"], fn m, at ->
        known.(m["ref"], at ++ ["ref"]) ++ mark_state(m, gone, at)
      end) ++
      each(w["scenes"], path ++ ["scenes"], fn s, at -> scene(s, w, index, known, at) end)
  end

  defp removed_rules(removed, index, gone_entities, path) do
    each(removed["entities"], path ++ ["entities"], &still_in_model(&1, index.entities, &2)) ++
      each(removed["relationships"], path ++ ["relationships"], fn r, at ->
        still_in_model(r, index.relationships, at) ++ removed_ends(r, index, gone_entities, at)
      end) ++
      each(removed["transitions"], path ++ ["transitions"], &removed_transition(&1, index, &2))
  end

  defp still_in_model(element, model, path) do
    if Map.has_key?(model, element["id"]),
      do: [
        Issue.error(
          Issue.path(path ++ ["id"]),
          ~s("#{element["id"]}" is removed but still in the model)
        )
      ],
      else: []
  end

  # A removed relationship's ends are in the model, or removed too.
  defp removed_ends(r, index, gone_entities, path) do
    for end_ <- ["source", "target"],
        not Map.has_key?(index.entities, r[end_]),
        not MapSet.member?(gone_entities, r[end_]) do
      Issue.error(Issue.path(path ++ [end_]), ~s(Unknown entity "#{r[end_]}"))
    end
  end

  defp removed_transition(t, index, path) do
    case behavior(index, t["stateMachine"], "state-machine") do
      nil ->
        [
          Issue.error(
            Issue.path(path ++ ["stateMachine"]),
            ~s(Unknown state machine "#{t["stateMachine"]}")
          )
        ]

      machine ->
        for end_ <- ["from", "to"], not has_id?(machine, "states", t["transition"][end_]) do
          Issue.error(
            Issue.path(path ++ ["transition", end_]),
            ~s(Unknown state "#{t["transition"][end_]}")
          )
        end
    end
  end

  defp story(%{"kind" => "change", "story" => story}, path) do
    for side <- ["before", "after"], is_nil(story[side]) or story[side] == "" do
      Issue.error(
        Issue.path(path ++ ["story", side]),
        ~s(A change walkthrough needs "story.#{side}"),
        ~s(Say in one line how it is #{side} the change, or set "kind": "tour" for a tour of code as it is.)
      )
    end
  end

  defp story(_walkthrough, _path), do: []

  defp tour_marks(%{"kind" => "tour", "marks" => marks}, path) do
    each(marks, path ++ ["marks"], fn _, at ->
      [
        Issue.error(
          Issue.path(at),
          "A tour has no marks",
          ~s(A tour shows code as it is. Remove the marks, or set "kind": "change".)
        )
      ]
    end)
  end

  defp tour_marks(_walkthrough, _path), do: []

  defp view_ref(nil, _index, _path), do: []

  defp view_ref(id, index, path) do
    if Map.has_key?(index.views, id),
      do: [],
      else: [Issue.error(Issue.path(path), ~s(Unknown view "#{id}"))]
  end

  defp mark_state(m, gone, path) do
    case Ref.parse(m["ref"]) do
      {:ok, ref} ->
        removed? = MapSet.member?(gone, Ref.key(ref))

        cond do
          m["state"] == "removed" and not removed? ->
            [
              Issue.error(
                Issue.path(path ++ ["state"]),
                ~s("#{m["ref"]}" is marked removed but is not in "removed")
              )
            ]

          m["state"] != "removed" and removed? ->
            [
              Issue.error(
                Issue.path(path ++ ["state"]),
                ~s("#{m["ref"]}" is in "removed" but marked #{m["state"]})
              )
            ]

          true ->
            []
        end

      :error ->
        []
    end
  end

  defp scene(s, w, index, known, path) do
    tour_code(s, w, path) ++
      view_ref(s["view"], index, path ++ ["view"]) ++
      each(s["focus"], path ++ ["focus"], known) ++
      each(s["callouts"], path ++ ["callouts"], &known.(&1["target"], &2 ++ ["target"])) ++
      each(s["trace"], path ++ ["trace"], &known.(&1["ref"], &2 ++ ["ref"])) ++
      each(s["effects"], path ++ ["effects"], &known.(&1["target"], &2 ++ ["target"])) ++
      each(s["badges"], path ++ ["badges"], &known.(&1["target"], &2 ++ ["target"]))
  end

  # A tour shows code as it is: only unchanged lines.
  defp tour_code(s, %{"kind" => "tour"}, path) do
    for {c, k} <- Enum.with_index(s["code"]),
        {h, i} <- Enum.with_index(c["hunks"]),
        {l, j} <- Enum.with_index(h["lines"]),
        l["kind"] != "ctx" do
      Issue.error(
        Issue.path(path ++ ["code", k, "hunks", i, "lines", j, "kind"]),
        ~s(A tour shows code as it is, but this line is "#{l["kind"]}"),
        ~s(Show an excerpt with "start" and "text", or use "ctx" lines.)
      )
    end
  end

  defp tour_code(_scene, _walkthrough, _path), do: []

  defp known_ref(key, path, index, gone) do
    case Ref.parse(key) do
      :error ->
        [
          Issue.error(
            Issue.path(path),
            ~s("#{key}" is not a ref),
            ~s(Write refs as "entity:<id>", "relationship:<id>", "state:<machine>:<id>", "transition:<machine>:<id>", "message:<interaction>:<id>" or "dataType:<id>#<field>".)
          )
        ]

      {:ok, ref} ->
        if exists?(ref, index) or MapSet.member?(gone, Ref.key(ref)),
          do: [],
          else: [
            Issue.error(
              Issue.path(path),
              ~s(Nothing in the model matches "#{key}"),
              did_you_mean(key, ref_keys(index, gone), "element")
            )
          ]
    end
  end

  # Every ref key of a document, for suggestions.
  defp ref_keys(index, gone) do
    Enum.to_list(gone) ++
      Enum.map(Map.keys(index.entities), &"entity:#{&1}") ++
      Enum.map(Map.keys(index.relationships), &"relationship:#{&1}") ++
      Enum.flat_map(index.data_types, fn {id, d} ->
        ["dataType:#{id}" | Enum.map(d["fields"], &"dataType:#{id}##{&1["name"]}")]
      end) ++
      Enum.map(Map.keys(index.use_cases), &"useCase:#{&1}") ++
      Enum.flat_map(index.behaviors, fn {id, b} -> ["behavior:#{id}" | behavior_keys(id, b)] end)
  end

  defp behavior_keys(id, %{"kind" => "interaction"} = b),
    do: Enum.map(messages(b["steps"]), &"message:#{id}:#{&1["id"]}")

  defp behavior_keys(id, %{"kind" => "activity"} = b),
    do: Enum.map(b["nodes"], &"activityNode:#{id}:#{&1["id"]}")

  defp behavior_keys(id, %{"kind" => "state-machine"} = b),
    do:
      Enum.map(b["states"], &"state:#{id}:#{&1["id"]}") ++
        Enum.map(b["transitions"], &"transition:#{id}:#{&1["id"]}")

  # ── R12, W1 ─────────────────────────────────────────────────────────────

  defp default_view(doc, index) do
    case doc["project"]["defaultView"] do
      nil ->
        []

      id ->
        if Map.has_key?(index.views, id),
          do: [],
          else: [Issue.error("project.defaultView", ~s(Unknown view "#{id}"))]
    end
  end

  defp styles(doc, _index) do
    styled = doc["presentation"]["kinds"]

    doc["model"]["entities"]
    |> Enum.map(& &1["kind"])
    |> Enum.uniq()
    |> Enum.reject(&Map.has_key?(styled, &1))
    |> Enum.map(
      &Issue.warning(
        "presentation.kinds.#{&1}",
        ~s(No style for entity kind "#{&1}"; readers use a default)
      )
    )
  end

  # ── §8.4: extensions ────────────────────────────────────────────────────

  defp extensions(doc, _index) do
    declared = MapSet.new(doc["extensions"], & &1["name"])
    m = doc["model"]

    uses =
      each(doc["extensions"], ["extensions"], fn use, at ->
        if use["required"],
          do: [
            Issue.error(
              Issue.path(at),
              ~s(This document requires the "#{use["name"]}" extension, which this reader does not know)
            )
          ],
          else: [
            Issue.warning(
              Issue.path(at),
              ~s(Extension "#{use["name"]}" is not known here; its data is kept but not checked)
            )
          ]
      end)

    uses ++
      each(m["entities"], ["model", "entities"], fn e, at ->
        kind(e["kind"], @core_entity_kinds, declared, at ++ ["kind"]) ++
          facets(e["ext"], declared, at)
      end) ++
      each(m["relationships"], ["model", "relationships"], fn r, at ->
        kind(r["kind"], @core_relationship_kinds, declared, at ++ ["kind"]) ++
          facets(r["ext"], declared, at)
      end) ++
      each(m["dataTypes"], ["model", "dataTypes"], &facets(&1["ext"], declared, &2)) ++
      each(m["useCases"], ["model", "useCases"], &facets(&1["ext"], declared, &2)) ++
      each(doc["views"], ["views"], fn v, at ->
        facets(v["ext"], declared, at) ++ extension_view(v, declared, at)
      end)
  end

  defp kind(kind, core, declared, path) do
    cond do
      kind in core ->
        []

      not String.contains?(kind, "/") ->
        [Issue.error(Issue.path(path), ~s(Unknown kind "#{kind}"))]

      true ->
        [namespace | _] = String.split(kind, "/", parts: 2)

        if MapSet.member?(declared, namespace),
          do: [],
          else: [
            Issue.error(
              Issue.path(path),
              ~s(Kind "#{kind}" uses the undeclared extension "#{namespace}")
            )
          ]
    end
  end

  defp facets(ext, declared, path) do
    for namespace <- ext |> Map.keys() |> Enum.sort(), not MapSet.member?(declared, namespace) do
      Issue.error(
        Issue.path(path ++ ["ext", namespace]),
        ~s(Data for the undeclared extension "#{namespace}")
      )
    end
  end

  defp extension_view(%{"type" => "extension", "extension" => name}, declared, path) do
    [namespace | _] = String.split(name, "/", parts: 2)

    if MapSet.member?(declared, namespace),
      do: [],
      else: [
        Issue.error(
          Issue.path(path ++ ["extension"]),
          ~s(View uses the undeclared extension "#{namespace}")
        )
      ]
  end

  defp extension_view(_view, _declared, _path), do: []

  # ── "Did you mean" ──────────────────────────────────────────────────────

  @doc false
  @spec suggest(String.t(), Enumerable.t()) :: [String.t()]
  def suggest(value, candidates) do
    scored =
      for c <- candidates,
          d = distance(value, c),
          d <= max(2, div(max(String.length(value), String.length(c)), 3)) or
            String.contains?(c, value) or
            String.contains?(value, c) do
        {d, c}
      end

    case Enum.sort(scored) do
      [] ->
        []

      [{best, _} | _] = sorted ->
        sorted
        |> Enum.filter(fn {d, _} -> d <= best + 1 end)
        |> Enum.take(3)
        |> Enum.map(&elem(&1, 1))
    end
  end

  defp did_you_mean(value, candidates, what) do
    case suggest(value, candidates) do
      [] -> "Add a #{what} with this id, or use an existing one."
      found -> "Did you mean #{Enum.map_join(found, " or ", &~s("#{&1}"))}?"
    end
  end

  # Levenshtein distance, one row at a time.
  defp distance(a, b) do
    b = String.graphemes(b)
    first = Enum.to_list(0..length(b))

    a
    |> String.graphemes()
    |> Enum.with_index(1)
    |> Enum.reduce(first, fn {ca, i}, above -> row(ca, i, b, above) end)
    |> List.last()
  end

  # The next row: each cell from the cell to its left, above, and above-left.
  defp row(ca, i, b, above) do
    above = List.to_tuple(above)

    b
    |> Enum.with_index(1)
    |> Enum.reduce([i], fn {cb, j}, [left | _] = acc ->
      cost = if ca == cb, do: 0, else: 1
      [min(min(elem(above, j) + 1, left + 1), elem(above, j - 1) + cost) | acc]
    end)
    |> Enum.reverse()
  end
end
