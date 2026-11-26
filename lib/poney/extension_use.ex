defmodule Poney.ExtensionUse do
  @moduledoc """
  An extension a document uses (§8.1). A reader that does not know a required one refuses the document.
  """

  use Poney.Struct,
    fields: [
      name: :value,
      version: :value,
      required: :value
    ]

  @type t :: %__MODULE__{
          name: String.t(),
          version: String.t(),
          required: boolean()
        }
end
