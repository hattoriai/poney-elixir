defmodule Poney.Scene.Effect do
  @moduledoc """
  What a reader must see on an element, by meaning: `"flow"`, `"attention"`, `"hot-path"`, `"slow"`, `"failing"` or `"blocked"`.
  """

  use Poney.Struct,
    fields: [
      target: :value,
      as: :value,
      tone: :value
    ]

  @type t :: %__MODULE__{
          target: String.t(),
          as: String.t(),
          tone: String.t() | nil
        }
end
