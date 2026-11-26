defmodule Poney.Model.UseCase do
  @moduledoc """
  A UML use case (§5.7): something an actor does with the system.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      name: :value,
      summary: :value,
      area: :value,
      actors: :value,
      supporting: :value,
      realized_by: :value,
      behaviors: :value,
      includes: :value,
      ext: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          summary: String.t(),
          area: String.t(),
          actors: [String.t()],
          supporting: [String.t()],
          realized_by: [String.t()],
          behaviors: [String.t()],
          includes: [String.t()],
          ext: %{optional(String.t()) => term()}
        }
end
