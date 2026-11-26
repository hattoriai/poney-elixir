defmodule Poney.Model.DataFlow do
  @moduledoc """
  Data moving from one entity to another (§5.5). `via` is the relationship that carries it, when one does.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      source: :value,
      target: :value,
      data: :value,
      label: :value,
      description: :value,
      via: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          source: String.t(),
          target: String.t(),
          data: [String.t()],
          label: String.t(),
          description: String.t() | nil,
          via: String.t() | nil
        }
end
