defmodule Poney.Scene.Badge do
  @moduledoc """
  A short fact pinned on an element: a count, a latency, a size.
  """

  use Poney.Struct,
    fields: [
      target: :value,
      text: :value,
      tone: :value
    ]

  @type t :: %__MODULE__{
          target: String.t(),
          text: String.t(),
          tone: String.t() | nil
        }
end
