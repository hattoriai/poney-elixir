defmodule Poney.Scene.Callout do
  @moduledoc """
  A numbered note on an element, in reading order.
  """

  use Poney.Struct,
    fields: [
      target: :value,
      text: :value
    ]

  @type t :: %__MODULE__{
          target: String.t(),
          text: String.t()
        }
end
