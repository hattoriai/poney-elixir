defmodule Poney.Presentation.Override do
  @moduledoc """
  A style override for one element.
  """

  use Poney.Struct,
    fields: [
      tone: :value,
      icon: :value,
      width: :value,
      height: :value,
      emphasis: :value
    ]

  @type t :: %__MODULE__{
          tone: String.t() | nil,
          icon: String.t() | nil,
          width: number() | nil,
          height: number() | nil,
          emphasis: boolean() | nil
        }
end
