defmodule Poney.Model.Relationship do
  @moduledoc """
  How one entity uses another (§5.2), such as `"calls"` or `"publishes"`. `data` lists the data types that travel along it.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      kind: :value,
      source: :value,
      target: :value,
      label: :value,
      description: :value,
      protocol: :value,
      data: :value,
      metadata: :value,
      ext: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          kind: String.t(),
          source: String.t(),
          target: String.t(),
          label: String.t(),
          description: String.t() | nil,
          protocol: String.t() | nil,
          data: [String.t()],
          metadata: %{optional(String.t()) => String.t() | number() | boolean()},
          ext: %{optional(String.t()) => term()}
        }
end
