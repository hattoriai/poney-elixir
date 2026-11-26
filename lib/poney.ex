defmodule Poney do
  @moduledoc ~S"""
  The Poney format in Elixir: read and check Poney documents, as the
  [specification](https://github.com/hattoriai/poney/blob/main/spec/SPEC.md)
  says.

  A Poney document (`.poney`, JSON) describes software, its views and its
  walkthroughs: stories that explain one change, or tours of code as it is.
  This library is a conforming reader and writer (§2). It draws nothing;
  the drawings are Poney's JavaScript packages.

      {:ok, doc} = Poney.read(File.read!("change.poney"))

      for walkthrough <- doc.walkthroughs, scene <- walkthrough.scenes do
        IO.puts("#{scene.title}: #{scene.text}")
      end

  Reading a document takes these steps, each from the specification:

    1. A document written for an earlier version of the format is upgraded
       (§11): version 0.1.0 opens as it is.
    2. Its shape must match the format's published JSON Schema (§9.1). A
       member that the format does not know is an error.
    3. Code is a diff or an excerpt, not both.
    4. The canonical form: every default filled in, and views written inside
       walkthrough scenes moved into `views` (§5.8).
    5. The rules that JSON Schema cannot say (§9.2): unique identifiers,
       references that exist, well-formed behaviors and walkthroughs. A
       required extension that this reader does not know is an error; an
       optional one is kept, with a warning (§8.4).

  Every problem is a `Poney.Issue`, with the path of the value, such as
  `"model.relationships.4.target"`, and often a hint.
  """

  alias Poney.{Canonical, Document, Issue, Rules, Schema, Upgrade, Writer}

  @typedoc "A document: JSON text, or JSON already decoded (maps with string keys)."
  @type input :: String.t() | map()

  @doc """
  Reads a document.

  Returns the document in its canonical form, as structs, or every issue
  when there is at least one error. Warnings alone do not stop a document;
  `check/1` lists them.
  """
  @spec read(input()) :: {:ok, Document.t()} | {:error, [Issue.t()]}
  def read(input) do
    with {:ok, canonical} <- canonical(input), do: {:ok, Document.from_json(canonical)}
  end

  @doc "Reads a document, or raises `Poney.InvalidDocumentError`."
  @spec read!(input()) :: Document.t()
  def read!(input) do
    case read(input) do
      {:ok, document} -> document
      {:error, issues} -> raise Poney.InvalidDocumentError, issues: issues
    end
  end

  @doc """
  Every issue of a document, errors and warnings, as an author or an agent
  needs them to fix it. An empty list means a valid document with nothing
  to report.
  """
  @spec check(input()) :: [Issue.t()]
  def check(input), do: input |> run() |> elem(1)

  @doc """
  The canonical form of a document, as JSON (maps with string keys): what
  `read/1` turns into structs. Use it to store or send a document that
  other readers will read.
  """
  @spec canonical(input()) :: {:ok, map()} | {:error, [Issue.t()]}
  def canonical(input) do
    case run(input) do
      {canonical, issues} when is_map(canonical) ->
        if Enum.any?(issues, &(&1.severity == :error)),
          do: {:error, issues},
          else: {:ok, canonical}

      {nil, issues} ->
        {:error, issues}
    end
  end

  @doc """
  Writes a document as `.poney` text: JSON indented by two spaces, members
  in the format's order, and a final newline.

  The document is checked first, as `read/1` checks one: a writer gives
  only documents a reader accepts (§2). Reading a document and writing it
  keeps everything in it, data of unknown extensions too.

      {:ok, doc} = Poney.read(File.read!("change.poney"))
      {:ok, text} = Poney.write(%{doc | project: %{doc.project | name: "Kestrel"}})
      File.write!("change.poney", text)
  """
  @spec write(Document.t()) :: {:ok, String.t()} | {:error, [Issue.t()]}
  def write(%Document{} = document) do
    with {:ok, _canonical} <- canonical(Writer.to_json(document)),
         do: {:ok, Writer.to_text(document)}
  end

  @doc "Writes a document, or raises `Poney.InvalidDocumentError`."
  @spec write!(Document.t()) :: String.t()
  def write!(document) do
    case write(document) do
      {:ok, text} -> text
      {:error, issues} -> raise Poney.InvalidDocumentError, issues: issues
    end
  end

  @doc "A document as JSON (maps with string keys), without checking it."
  @spec to_json(Document.t()) :: map()
  def to_json(%Document{} = document), do: Writer.to_json(document)

  @doc "The version of the format this library reads and writes, such as `\"0.2.0\"`."
  @spec format_version() :: String.t()
  def format_version, do: Schema.version()

  # The steps of reading, in order. Shape errors stop it: the rules need a
  # document of the right shape.
  defp run(input) do
    with {:ok, json} <- decode(input),
         {shaped, []} <- Schema.check(Upgrade.upgrade(json)),
         [] <- Canonical.check_code(shaped) do
      canonical = Canonical.canonical(shaped)
      {canonical, Rules.check(canonical)}
    else
      {:error, issue} -> {nil, [issue]}
      {_shaped, [_ | _] = issues} -> {nil, issues}
      [_ | _] = issues -> {nil, issues}
    end
  end

  defp decode(input) when is_binary(input) do
    case JSON.decode(input) do
      {:ok, json} ->
        {:ok, json}

      {:error, reason} ->
        {:error, Issue.error("", "The document is not JSON: #{inspect(reason)}")}
    end
  end

  defp decode(input) when is_map(input), do: {:ok, input}
end
