defmodule Poney.Walkthrough.Story do
  @moduledoc """
  What changes for a person (a change, with `before` and `after`), or what the code is for (a tour).
  """

  use Poney.Struct,
    fields: [
      text: :value,
      before: :value,
      after: :value
    ]

  @type t :: %__MODULE__{
          text: String.t(),
          before: String.t() | nil,
          after: String.t() | nil
        }
end
