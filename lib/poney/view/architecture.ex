defmodule Poney.View.Architecture do
  @moduledoc """
  An architecture view (§6): entities, the relationships between them, groups, and containers drawn closed.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      type: :value,
      title: :value,
      description: :value,
      category: :value,
      positions: :value,
      ext: :value,
      entities: :value,
      relationships: :value,
      groups: {:list, Poney.View.Group},
      collapsed: :value,
      layout: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          title: String.t(),
          description: String.t(),
          category: String.t(),
          positions: %{optional(String.t()) => %{String.t() => number()}},
          ext: %{optional(String.t()) => term()},
          entities: [String.t()],
          relationships: [String.t()] | nil,
          groups: [Poney.View.Group.t()],
          collapsed: [String.t()],
          layout: %{String.t() => String.t()}
        }
end
