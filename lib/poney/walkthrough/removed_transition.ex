defmodule Poney.Walkthrough.RemovedTransition do
  @moduledoc """
  A transition a change removes, with its state machine.
  """

  use Poney.Struct,
    fields: [
      state_machine: :value,
      transition: Poney.Model.Transition
    ]

  @type t :: %__MODULE__{
          state_machine: String.t(),
          transition: Poney.Model.Transition.t()
        }
end
