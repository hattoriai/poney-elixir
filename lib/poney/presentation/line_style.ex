defmodule Poney.Presentation.LineStyle do
  @moduledoc """
  The style of a relationship kind: a pattern and the marker at its target end.
  """

  use Poney.Struct,
    fields: [
      pattern: :value,
      head: :value
    ]

  @type t :: %__MODULE__{
          pattern: String.t(),
          head: String.t()
        }
end
