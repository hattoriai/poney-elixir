# Walkthroughs

A walkthrough explains software as a story in scenes. There are two kinds:

- **A change** (`kind: "change"`) explains one change, such as a pull
  request: what changes for a person (`story.before` and `story.after`), a
  verdict, then the scenes. Its `marks` say which elements the change adds,
  changes or removes. The model describes the system *after* the change;
  `removed` holds what the change removes, so it can be drawn as it was.
- **A tour** (`kind: "tour"`) explains code as it is, to someone new to it.
  It has no marks, and its code is only unchanged lines.

```elixir
{:ok, doc} = Poney.read(File.read!("change.poney"))
[walkthrough | _] = doc.walkthroughs
```

## A scene

| Field | What it is |
|---|---|
| `title`, `text` | The scene's title, and its point in plain words |
| `view` | The id of the view it shows, or `nil` for a scene of code only |
| `focus` | Refs to frame and keep bright; the rest of the view dims |
| `callouts` | Numbered notes on elements, in reading order |
| `code` | Code to read, as diff hunks (an excerpt is one hunk of `"ctx"` lines) |
| `proof` | Tests, checks, runs; `missing: true` marks proof that does not exist yet |
| `cases` | What the code does in each case |
| `trace` | A path the reader can play, step by step |
| `effects`, `badges` | Emphasis by meaning (`"slow"`, `"failing"`…) and short facts on elements |
| `question`, `questions` | A decision for a reviewer, or a check of understanding in a tour |
| `risk` | `"look"` when the scene needs a close look, else `"routine"` |

## Refs

Scenes and marks name elements by refs, such as `"entity:order-service"` or
`"transition:order-lifecycle:t-retry"`. `Poney.Ref` reads them:

```elixir
{:ok, ref} = Poney.Ref.parse("entity:order-service")
Enum.find(doc.model.entities, &(&1.id == ref.id)).name
#=> "Order service"
```

A mark's ref may name an element of `walkthrough.removed`: one the change
removes.

## Show a scene in a page

The library has the story; Poney's `<poney-diagram>` element draws the
picture. In a Phoenix page, write the scene's text with your own components,
and give the element the document and the scene:

```heex
<article :for={scene <- @walkthrough.scenes}>
  <h2>{scene.title}</h2>
  <p>{scene.text}</p>

  <poney-diagram
    :if={scene.view}
    id={"scene-#{scene.id}"}
    phx-update="ignore"
    walkthrough={@walkthrough.id}
    scene={scene.id}
  >
    <script type="application/json">{Phoenix.HTML.raw(@json)}</script>
  </poney-diagram>
</article>
```

`@json` is the document's JSON text, safe inside a `<script>` element:

```elixir
# "</" written as "<\/" is the same JSON, and text in the document
# (written by an agent) cannot close the script element.
json = doc |> Poney.write!() |> String.replace("</", "<\\/")
```

The element sends
`poney-select` and `poney-hover` events with the ref the reader clicks or
points at; a LiveView hook can push them to the server. Load the element's
`poney.js` and `poney.css` from the npm package `@hattoriai/poney-element`.
