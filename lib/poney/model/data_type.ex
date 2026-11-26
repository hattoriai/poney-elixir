defmodule Poney.Model.DataType do
  @moduledoc """
  A table, record, event or document (§5.3), with its fields, its owner and where it is stored.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      kind: :value,
      name: :value,
      summary: :value,
      description: :value,
      fields: {:list, Poney.Model.Field},
      owned_by: :value,
      stored_in: :value,
      source_refs: {:list, Poney.Model.SourceRef},
      ext: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          kind: String.t(),
          name: String.t(),
          summary: String.t(),
          description: String.t() | nil,
          fields: [Poney.Model.Field.t()],
          owned_by: String.t() | nil,
          stored_in: String.t() | nil,
          source_refs: [Poney.Model.SourceRef.t()],
          ext: %{optional(String.t()) => term()}
        }
end
