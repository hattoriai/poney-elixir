defmodule Poney.Canonical do
  @moduledoc false

  # After the shape check and its defaults, the rest of the canonical form
  # (§5.8), so every reader sees one shape:
  #
  #   * code is a diff ("hunks") or an excerpt ("start" and "text"), never
  #     both; an excerpt becomes one hunk of unchanged lines;
  #   * a view written inside a walkthrough moves into "views", named after
  #     its walkthrough or scene, and the walkthrough points at it by id.

  alias Poney.Issue

  @doc "Checks the code blocks, which JSON Schema cannot say: diff or excerpt."
  @spec check_code(map()) :: [Issue.t()]
  def check_code(doc) do
    for {w, i} <- Enum.with_index(doc["walkthroughs"]),
        {s, j} <- Enum.with_index(w["scenes"]),
        {code, k} <- Enum.with_index(s["code"]),
        not diff_or_excerpt?(code) do
      Issue.error(
        Issue.path(["walkthroughs", i, "scenes", j, "code", k]),
        ~s|Give "hunks" (a diff), or "start" and "text" (an excerpt), not both|,
        ~s(A diff shows a change; an excerpt shows a file as it is, from line "start".)
      )
    end
  end

  defp diff_or_excerpt?(%{"hunks" => _} = code),
    do: not Map.has_key?(code, "text") and not Map.has_key?(code, "start")

  defp diff_or_excerpt?(code), do: Map.has_key?(code, "text") and Map.has_key?(code, "start")

  @doc "The canonical form of a document whose shape is right."
  @spec canonical(map()) :: map()
  def canonical(doc) do
    {walkthroughs, placed} =
      Enum.map_reduce(doc["walkthroughs"], [], fn w, placed ->
        {overview, placed} = place(w["overview"], "#{w["id"]}.overview", w["title"], placed)

        {scenes, placed} =
          Enum.map_reduce(w["scenes"], placed, fn s, placed ->
            {view, placed} = place(s["view"], "#{w["id"]}.#{s["id"]}", s["title"], placed)

            {s
             |> put_optional("view", view)
             |> Map.update!("code", &Enum.map(&1, fn c -> hunks(c) end)), placed}
          end)

        {w |> put_optional("overview", overview) |> Map.put("scenes", scenes), placed}
      end)

    %{doc | "walkthroughs" => walkthroughs, "views" => doc["views"] ++ Enum.reverse(placed)}
  end

  defp place(view, id, title, placed) when is_map(view) do
    view = view |> Map.put_new("id", id) |> Map.put_new("title", title)
    {view["id"], [view | placed]}
  end

  defp place(view, _id, _title, placed), do: {view, placed}

  defp put_optional(map, key, nil), do: Map.delete(map, key)
  defp put_optional(map, key, value), do: Map.put(map, key, value)

  # An excerpt: its lines, numbered from "start", as one hunk of unchanged lines.
  defp hunks(%{"text" => text, "start" => start} = code) do
    # JSON may write the line number as 3.0.
    start = trunc(start)

    lines =
      text
      |> String.replace_suffix("\n", "")
      |> String.split("\n")
      |> Enum.with_index(fn line, i -> %{"kind" => "ctx", "new" => start + i, "text" => line} end)

    code |> Map.drop(["text", "start"]) |> Map.put("hunks", [%{"lines" => lines}])
  end

  defp hunks(code), do: code
end
