defmodule PoneyTest do
  use ExUnit.Case, async: true

  alias Poney.Fixtures

  defp minimal, do: Fixtures.conformance("valid/minimal.poney")
  defp errors(input), do: for(%{severity: :error} = i <- Poney.check(input), do: i)

  describe "read/1" do
    test "takes JSON text or decoded JSON" do
      assert {:ok, doc} = Poney.read(JSON.encode!(minimal()))
      assert {:ok, ^doc} = Poney.read(minimal())
    end

    test "refuses text that is not JSON" do
      assert {:error, [%Poney.Issue{path: "", message: "The document is not JSON" <> _}]} =
               Poney.read("{")
    end

    test "refuses a member the format does not know, and says where" do
      doc = put_in(minimal(), ["project", "colour"], "red")

      assert {:error, [issue]} = Poney.read(doc)
      assert issue.path == "project.colour"
      assert issue.message == ~s(Unknown member "colour")
      assert issue.hint =~ "Remove"
    end

    test "names the field at fault inside a union, not the union" do
      doc = update_in(minimal(), ["views"], fn [v | rest] -> [Map.put(v, "title", 7) | rest] end)
      assert [%{path: "views.0.title", message: "Expected string, received number"}] = errors(doc)

      doc =
        update_in(minimal(), ["views"], fn [v | rest] -> [Map.put(v, "type", "pie") | rest] end)

      assert [%{path: "views.0.type", hint: "Use one of: " <> _}] = errors(doc)
    end

    test "fills in the defaults: the canonical form" do
      {:ok, doc} = Poney.read(Map.delete(minimal(), "presentation"))
      assert doc.walkthroughs == []
      assert doc.presentation.kinds["service"].shape == "card"
      assert Enum.all?(doc.model.entities, &(&1.tags == [] and &1.ext == %{}))
    end

    test "read!/1 raises with every issue" do
      doc = put_in(minimal(), ["project", "id"], "Not An Id")
      error = assert_raise Poney.InvalidDocumentError, fn -> Poney.read!(doc) end
      assert Exception.message(error) =~ ~s(project.id: "Not An Id" is not an identifier)
    end
  end

  describe "walkthroughs" do
    setup do
      {:ok, doc} = Poney.read(Fixtures.example("kestrel-commerce"))
      %{doc: doc}
    end

    test "scenes point at views by id, also views written inside them", %{doc: doc} do
      ids = MapSet.new(doc.views, & &1.id)

      for w <- doc.walkthroughs, s <- w.scenes, s.view do
        assert is_binary(s.view) and MapSet.member?(ids, s.view)
      end
    end

    test "an excerpt is one hunk of unchanged lines, numbered from its start" do
      doc =
        update_in(minimal(), ["walkthroughs"], fn _ ->
          [
            %{
              "id" => "t",
              "kind" => "tour",
              "title" => "T",
              "summary" => "S",
              "story" => %{"text" => "Why"},
              "scenes" => [
                %{
                  "id" => "s",
                  "title" => "S",
                  "text" => "T",
                  "code" => [%{"path" => "a.ex", "start" => 10, "text" => "a\nb\n"}]
                }
              ]
            }
          ]
        end)

      {:ok, %{walkthroughs: [%{scenes: [%{code: [code]}]}]}} = Poney.read(doc)

      assert [%{lines: [%{kind: "ctx", new: 10, text: "a"}, %{kind: "ctx", new: 11, text: "b"}]}] =
               code.hunks
    end

    test "code is a diff or an excerpt, not both" do
      doc = Fixtures.example("walkthrough")
      [w | _] = doc["walkthroughs"]
      [s | rest] = w["scenes"]

      code = [
        %{
          "path" => "a.ex",
          "start" => 1,
          "text" => "x",
          "hunks" => [%{"lines" => [%{"kind" => "ctx", "text" => "x"}]}]
        }
      ]

      doc =
        Map.put(doc, "walkthroughs", [Map.put(w, "scenes", [Map.put(s, "code", code) | rest])])

      assert [%{path: "walkthroughs.0.scenes.0.code.0", message: "Give \"hunks\"" <> _}] =
               errors(doc)
    end
  end

  describe "the format's versions" do
    test "opens a 0.1.0 document with the current names" do
      old =
        minimal()
        |> Map.put("poneyVersion", "0.1.0")
        |> update_in(["model", "entities"], fn [e | rest] ->
          [Map.put(e, "kind", "module") | rest]
        end)

      assert {:ok, doc} = Poney.read(old)
      assert doc.poney_version == "0.2.0"
      assert hd(doc.model.entities).kind == "component"
      assert Poney.format_version() == "0.2.0"
    end
  end

  describe "write/1" do
    test "writes what it read, and reads it back the same" do
      for name <- ~w(kestrel-commerce tour walkthrough) do
        {:ok, doc} = Poney.read(Fixtures.example(name))
        assert {:ok, text} = Poney.write(doc)
        assert String.ends_with?(text, "}\n")
        assert {:ok, ^doc} = Poney.read(text)
        assert Poney.to_json(doc) == elem(Poney.canonical(Fixtures.example(name)), 1)
      end
    end

    test "indents by two spaces, members in the format's order" do
      {:ok, doc} = Poney.read(minimal())
      text = Poney.write!(doc)
      assert text =~ ~r/\A\{\n  "poneyVersion": "0\.2\.0",\n  "project": \{\n    "id": /
    end

    test "keeps the data of extensions it does not know" do
      doc = Fixtures.conformance("valid/unknown-optional-extension.poney")
      {:ok, read} = Poney.read(doc)
      assert {:ok, text} = Poney.write(read)
      assert JSON.decode!(text) == elem(Poney.canonical(doc), 1)
    end

    test "refuses to write a document a reader would refuse" do
      {:ok, doc} = Poney.read(minimal())
      [e | rest] = doc.model.entities
      doc = put_in(doc.model.entities, [%{e | parent: "nowhere"} | rest])

      assert {:error, [%{path: "model.entities.0.parent"} | _]} = Poney.write(doc)
      assert_raise Poney.InvalidDocumentError, fn -> Poney.write!(doc) end
    end
  end
end
