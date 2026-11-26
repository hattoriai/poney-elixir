defmodule Poney.Model.SourceRef do
  @moduledoc """
  Where an element is in the code: a path in the repository, and optionally a line and a symbol.
  """

  use Poney.Struct,
    fields: [
      path: :value,
      line: :value,
      symbol: :value,
      repository: :value
    ]

  @type t :: %__MODULE__{
          path: String.t(),
          line: integer() | nil,
          symbol: String.t() | nil,
          repository: String.t() | nil
        }
end
