defmodule Poney.Model.ActivityNode do
  @moduledoc """
  A node of an activity. `performed_by` is the entity that does it: its swimlane.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      kind: :value,
      label: :value,
      description: :value,
      performed_by: :value,
      outcome: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          kind: String.t(),
          label: String.t(),
          description: String.t() | nil,
          performed_by: String.t() | nil,
          outcome: String.t() | nil
        }
end
