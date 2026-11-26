defmodule Poney.Model.Branch do
  @moduledoc """
  A branch of a fragment: its guard and its steps.
  """

  use Poney.Struct,
    fields: [
      guard: :value,
      steps: {:list, Poney.Model.Step}
    ]

  @type t :: %__MODULE__{
          guard: String.t(),
          steps: [Poney.Model.Step.t()]
        }
end
