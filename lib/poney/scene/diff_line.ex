defmodule Poney.Scene.DiffLine do
  @moduledoc """
  A line of a diff: `kind` is `"add"`, `"del"` or `"ctx"`; `old` and `new` are its line numbers on each side.
  """

  use Poney.Struct,
    fields: [
      kind: :value,
      old: :value,
      new: :value,
      text: :value
    ]

  @type t :: %__MODULE__{
          kind: String.t(),
          old: pos_integer() | nil,
          new: pos_integer() | nil,
          text: String.t()
        }
end
