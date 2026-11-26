defmodule Poney.Scene.TraceStep do
  @moduledoc """
  One step of a path the reader can play: a line, a message, a transition, or a box to stop at.
  """

  use Poney.Struct,
    fields: [
      ref: :value,
      caption: :value
    ]

  @type t :: %__MODULE__{
          ref: String.t(),
          caption: String.t() | nil
        }
end
