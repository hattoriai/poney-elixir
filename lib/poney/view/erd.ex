defmodule Poney.View.Erd do
  @moduledoc """
  An entity relationship diagram of some data types.
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
      data_types: :value,
      group_by_store: :value,
      field_limit: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          title: String.t(),
          description: String.t(),
          category: String.t(),
          positions: %{optional(String.t()) => %{String.t() => number()}},
          ext: %{optional(String.t()) => term()},
          data_types: [String.t()],
          group_by_store: boolean(),
          field_limit: pos_integer()
        }
end
