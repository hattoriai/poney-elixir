defmodule Poney.Model.State do
  @moduledoc """
  A state of a state machine: `kind` is `"initial"`, `"state"` or `"final"`.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      kind: :value,
      name: :value,
      description: :value,
      entry_actions: :value,
      outcome: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          kind: String.t(),
          name: String.t(),
          description: String.t() | nil,
          entry_actions: [String.t()],
          outcome: String.t()
        }
end
