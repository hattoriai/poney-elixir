defmodule Poney.View.Group do
  @moduledoc """
  A group of entities in a view: a zone in an architecture view, a layer in a dependency view.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      label: :value,
      description: :value,
      members: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          label: String.t(),
          description: String.t() | nil,
          members: [String.t()]
        }
end
