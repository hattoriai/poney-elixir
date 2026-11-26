defmodule Poney.View.Map do
  @moduledoc """
  A map (§6): a small, composed picture of how a dozen entities connect, for one explanation. Walkthrough scenes use it most.
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
      pass_through: :value,
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
          pass_through: [String.t()],
          collapsed: [String.t()],
          layout: %{String.t() => String.t()}
        }
end
