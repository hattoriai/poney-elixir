defmodule Poney.Model.DataRelation do
  @moduledoc """
  A relation between two data types (§5.4), with crow's foot ends such as `"exactly-one"`. `logical` relations cross a service boundary and have no database constraint.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      from: :value,
      to: :value,
      from_cardinality: :value,
      to_cardinality: :value,
      label: :value,
      via: :value,
      logical: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          from: String.t(),
          to: String.t(),
          from_cardinality: String.t(),
          to_cardinality: String.t(),
          label: String.t(),
          via: String.t() | nil,
          logical: boolean()
        }
end
