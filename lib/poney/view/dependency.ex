defmodule Poney.View.Dependency do
  @moduledoc """
  A dependency diagram: entities in layers, top to bottom.
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
      layers: {:list, Poney.View.Group}
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
          layers: [Poney.View.Group.t()]
        }
end
