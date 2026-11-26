defmodule Poney.Scene.Case do
  @moduledoc """
  What the code does in one case.
  """

  use Poney.Struct,
    fields: [
      when: :value,
      then: :value,
      note: :value
    ]

  @type t :: %__MODULE__{
          when: String.t(),
          then: String.t(),
          note: String.t() | nil
        }
end
