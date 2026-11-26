defmodule Poney.Walkthrough.Fact do
  @moduledoc """
  A fact of a verdict: a label and a value.
  """

  use Poney.Struct,
    fields: [
      label: :value,
      value: :value
    ]

  @type t :: %__MODULE__{
          label: String.t(),
          value: String.t()
        }
end
