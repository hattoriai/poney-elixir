defmodule Poney.Scene.Note do
  @moduledoc """
  A note under a line of code.
  """

  use Poney.Struct,
    fields: [
      line: :value,
      text: :value
    ]

  @type t :: %__MODULE__{
          line: pos_integer(),
          text: String.t()
        }
end
