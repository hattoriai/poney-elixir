defmodule Poney.Model.Interaction do
  @moduledoc """
  A UML interaction (§5.6.1): participants, left to right, and the messages between them, in order.
  """

  use Poney.Struct,
    fields: [
      kind: :value,
      id: :value,
      name: :value,
      summary: :value,
      description: :value,
      participants: :value,
      steps: {:list, Poney.Model.Step}
    ]

  @type t :: %__MODULE__{
          kind: String.t(),
          id: String.t(),
          name: String.t(),
          summary: String.t(),
          description: String.t() | nil,
          participants: [String.t()],
          steps: [Poney.Model.Step.t()]
        }
end
