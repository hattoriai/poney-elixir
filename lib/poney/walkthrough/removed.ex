defmodule Poney.Walkthrough.Removed do
  @moduledoc """
  The elements a change removes, as they were.
  """

  use Poney.Struct,
    fields: [
      entities: {:list, Poney.Model.Entity},
      relationships: {:list, Poney.Model.Relationship},
      transitions: {:list, Poney.Walkthrough.RemovedTransition}
    ]

  @type t :: %__MODULE__{
          entities: [Poney.Model.Entity.t()],
          relationships: [Poney.Model.Relationship.t()],
          transitions: [Poney.Walkthrough.RemovedTransition.t()]
        }
end
