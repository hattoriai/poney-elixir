defmodule Poney.View.Extension do
  @moduledoc """
  A view whose type an extension defines (§8.3): `extension` names it as `"<extension>/<view type>"`, and `data` is the extension's.
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
      extension: :value,
      entities: :value,
      data: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          title: String.t(),
          description: String.t(),
          category: String.t(),
          positions: %{optional(String.t()) => %{String.t() => number()}},
          ext: %{optional(String.t()) => term()},
          extension: String.t(),
          entities: [String.t()],
          data: term()
        }
end
