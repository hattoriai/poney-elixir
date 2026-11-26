defmodule Poney.Model.ForeignKey do
  @moduledoc """
  The data type and field a foreign key points at.
  """

  use Poney.Struct,
    fields: [
      data_type: :value,
      field: :value
    ]

  @type t :: %__MODULE__{
          data_type: String.t(),
          field: String.t()
        }
end
