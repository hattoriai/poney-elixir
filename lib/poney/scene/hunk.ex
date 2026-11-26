defmodule Poney.Scene.Hunk do
  @moduledoc """
  A hunk of a diff.
  """

  use Poney.Struct,
    fields: [
      header: :value,
      lines: {:list, Poney.Scene.DiffLine}
    ]

  @type t :: %__MODULE__{
          header: String.t() | nil,
          lines: [Poney.Scene.DiffLine.t()]
        }
end
