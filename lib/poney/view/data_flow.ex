defmodule Poney.View.DataFlow do
  @moduledoc """
  A data flow diagram of some data flows.
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
      flows: :value,
      show_control_flow: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          title: String.t(),
          description: String.t(),
          category: String.t(),
          positions: %{optional(String.t()) => %{String.t() => number()}},
          ext: %{optional(String.t()) => term()},
          flows: [String.t()],
          show_control_flow: boolean()
        }
end
