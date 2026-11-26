defmodule Poney.Model.Fragment do
  @moduledoc """
  A combined fragment of an interaction (`"alt"`, `"opt"`, `"loop"` or `"par"`), with its branches.
  """

  use Poney.Struct,
    fields: [
      type: :value,
      id: :value,
      kind: :value,
      label: :value,
      branches: {:list, Poney.Model.Branch}
    ]

  @type t :: %__MODULE__{
          type: String.t(),
          id: String.t(),
          kind: String.t(),
          label: String.t(),
          branches: [Poney.Model.Branch.t()]
        }
end
