defmodule Poney.Walkthrough.Finding do
  @moduledoc """
  What a reviewer found: a `"risk"` to weigh or a `"note"`. `scene` is where it shows.
  """

  use Poney.Struct,
    fields: [
      text: :value,
      severity: :value,
      scene: :value
    ]

  @type t :: %__MODULE__{
          text: String.t(),
          severity: String.t(),
          scene: String.t() | nil
        }
end
