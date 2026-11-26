defmodule Poney.Model.ActivityFlow do
  @moduledoc """
  A flow between two nodes of an activity, with an optional guard.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      from: :value,
      to: :value,
      guard: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          from: String.t(),
          to: String.t(),
          guard: String.t() | nil
        }
end
