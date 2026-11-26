defmodule Poney.Scene do
  @moduledoc """
  A scene of a walkthrough: the point of it in plain words (`text`), the
  view it shows (`view`, an id; `nil` for a scene of code only), what to
  keep bright (`focus`), numbered notes on elements (`callouts`), the code,
  the proof, a path to play (`trace`), and emphasis by meaning (`effects`,
  `badges`). Refs are text, such as `"entity:order-service"`; see
  `Poney.Ref`.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      title: :value,
      text: :value,
      risk: :value,
      view: :value,
      focus: :value,
      callouts: {:list, Poney.Scene.Callout},
      cases: {:list, Poney.Scene.Case},
      proof: {:list, Poney.Scene.Proof},
      question: :value,
      questions: :value,
      code: {:list, Poney.Scene.CodeBlock},
      trace: {:list, Poney.Scene.TraceStep},
      effects: {:list, Poney.Scene.Effect},
      badges: {:list, Poney.Scene.Badge}
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          title: String.t(),
          text: String.t(),
          risk: String.t(),
          view: String.t() | nil,
          focus: [String.t()],
          callouts: [Poney.Scene.Callout.t()],
          cases: [Poney.Scene.Case.t()],
          proof: [Poney.Scene.Proof.t()],
          question: String.t() | nil,
          questions: [String.t()],
          code: [Poney.Scene.CodeBlock.t()],
          trace: [Poney.Scene.TraceStep.t()],
          effects: [Poney.Scene.Effect.t()],
          badges: [Poney.Scene.Badge.t()]
        }
end
