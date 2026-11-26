defmodule Poney.Walkthrough do
  @moduledoc """
  A walkthrough (§5.8): a story that explains one change (`kind: "change"`),
  or a tour of code as it is (`kind: "tour"`). Its scenes come in reading
  order. `marks` say what the change adds, changes or removes; `removed`
  holds the elements the change removes, to draw them as they were.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      kind: :value,
      title: :value,
      summary: :value,
      source: Poney.Walkthrough.Source,
      story: Poney.Walkthrough.Story,
      overview: :value,
      verdict: Poney.Walkthrough.Verdict,
      marks: {:list, Poney.Walkthrough.Mark},
      removed: Poney.Walkthrough.Removed,
      scenes: {:list, Poney.Scene}
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          kind: String.t(),
          title: String.t(),
          summary: String.t(),
          source: Poney.Walkthrough.Source.t() | nil,
          story: Poney.Walkthrough.Story.t(),
          overview: String.t() | nil,
          verdict: Poney.Walkthrough.Verdict.t() | nil,
          marks: [Poney.Walkthrough.Mark.t()],
          removed: Poney.Walkthrough.Removed.t(),
          scenes: [Poney.Scene.t()]
        }
end
