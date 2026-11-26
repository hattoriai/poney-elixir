defmodule Poney.Scene.CodeBlock do
  @moduledoc """
  Code to read, as diff hunks. An excerpt of a file as it is becomes one
  hunk of unchanged (`"ctx"`) lines. `notes` sit under a line, by its new
  line number.
  """

  use Poney.Struct,
    fields: [
      path: :value,
      title: :value,
      hunks: {:list, Poney.Scene.Hunk},
      notes: {:list, Poney.Scene.Note}
    ]

  @type t :: %__MODULE__{
          path: String.t(),
          title: String.t() | nil,
          hunks: [Poney.Scene.Hunk.t()],
          notes: [Poney.Scene.Note.t()]
        }
end
