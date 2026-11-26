defmodule Poney.View.Activity do
  @moduledoc """
  An activity diagram of one activity.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      type: :value,
      title: :value,
      description: :value,
      category: :value,
      positions: :value,
      ext: :value,
      activity: :value,
      swimlanes: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          type: String.t(),
          title: String.t(),
          description: String.t(),
          category: String.t(),
          positions: %{optional(String.t()) => %{String.t() => number()}},
          ext: %{optional(String.t()) => term()},
          activity: String.t(),
          swimlanes: boolean()
        }
end
