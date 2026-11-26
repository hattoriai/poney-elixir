defmodule Poney.Model.Activity do
  @moduledoc """
  A UML activity (§5.6.2): actions, decisions and the flows between them.
  """

  use Poney.Struct,
    fields: [
      kind: :value,
      id: :value,
      name: :value,
      summary: :value,
      description: :value,
      nodes: {:list, Poney.Model.ActivityNode},
      flows: {:list, Poney.Model.ActivityFlow}
    ]

  @type t :: %__MODULE__{
          kind: String.t(),
          id: String.t(),
          name: String.t(),
          summary: String.t(),
          description: String.t() | nil,
          nodes: [Poney.Model.ActivityNode.t()],
          flows: [Poney.Model.ActivityFlow.t()]
        }
end
