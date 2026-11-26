defmodule Poney.Project do
  @moduledoc """
  What a document describes (§3.2). `default_view` is the id of the view to open first.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      name: :value,
      description: :value,
      repository: :value,
      default_view: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          name: String.t(),
          description: String.t(),
          repository: String.t() | nil,
          default_view: String.t() | nil
        }
end
