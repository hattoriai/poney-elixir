defmodule Poney.Model.Transition do
  @moduledoc """
  A transition between two states, on an event, with an optional guard and actions.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      from: :value,
      to: :value,
      event: :value,
      guard: :value,
      actions: :value,
      description: :value,
      triggered_by: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          from: String.t(),
          to: String.t(),
          event: String.t(),
          guard: String.t() | nil,
          actions: [String.t()],
          description: String.t() | nil,
          triggered_by: String.t() | nil
        }
end
