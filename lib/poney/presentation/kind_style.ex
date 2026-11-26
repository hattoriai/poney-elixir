defmodule Poney.Presentation.KindStyle do
  @moduledoc """
  The style of an entity kind: a shape, a tone, a Lucide icon name and a label.
  """

  use Poney.Struct,
    fields: [
      shape: :value,
      tone: :value,
      icon: :value,
      label: :value
    ]

  @type t :: %__MODULE__{
          shape: String.t(),
          tone: String.t(),
          icon: String.t(),
          label: String.t()
        }
end
