defmodule Poney.Scene.Proof do
  @moduledoc """
  Evidence: a test, a check, a run. `missing` marks proof that does not exist yet.
  """

  use Poney.Struct,
    fields: [
      text: :value,
      source: :value,
      test: :value,
      missing: :value
    ]

  @type t :: %__MODULE__{
          text: String.t(),
          source: String.t() | nil,
          test: String.t() | nil,
          missing: boolean()
        }
end
