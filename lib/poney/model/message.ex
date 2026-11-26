defmodule Poney.Model.Message do
  @moduledoc """
  A message of an interaction: `kind` is `"call"`, `"return"`, `"async"` or `"self"`.
  """

  use Poney.Struct,
    fields: [
      type: :value,
      id: :value,
      kind: :value,
      from: :value,
      to: :value,
      label: :value,
      description: :value,
      relationship: :value,
      data: :value
    ]

  @type t :: %__MODULE__{
          type: String.t(),
          id: String.t(),
          kind: String.t(),
          from: String.t(),
          to: String.t(),
          label: String.t(),
          description: String.t() | nil,
          relationship: String.t() | nil,
          data: [String.t()]
        }
end
