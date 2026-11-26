defmodule Poney.Model.StateMachine do
  @moduledoc """
  A state machine (§5.6.3): the lifecycle of `subject`, owned by `owner`.
  """

  use Poney.Struct,
    fields: [
      kind: :value,
      id: :value,
      name: :value,
      summary: :value,
      description: :value,
      subject: :value,
      owner: :value,
      states: {:list, Poney.Model.State},
      transitions: {:list, Poney.Model.Transition}
    ]

  @type t :: %__MODULE__{
          kind: String.t(),
          id: String.t(),
          name: String.t(),
          summary: String.t(),
          description: String.t() | nil,
          subject: String.t() | nil,
          owner: String.t() | nil,
          states: [Poney.Model.State.t()],
          transitions: [Poney.Model.Transition.t()]
        }
end
