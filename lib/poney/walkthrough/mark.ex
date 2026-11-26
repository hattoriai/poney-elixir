defmodule Poney.Walkthrough.Mark do
  @moduledoc """
  A mark: the element `ref` is `"new"`, `"changed"` or `"removed"` in the change.
  """

  use Poney.Struct,
    fields: [
      ref: :value,
      state: :value,
      note: :value
    ]

  @type t :: %__MODULE__{
          ref: String.t(),
          state: String.t(),
          note: String.t() | nil
        }
end
