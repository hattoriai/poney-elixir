defmodule Poney.Model.Field do
  @moduledoc """
  A field of a data type (§5.3). `references` is its foreign key, when it has one.
  """

  use Poney.Struct,
    fields: [
      name: :value,
      type: :value,
      description: :value,
      primary_key: :value,
      nullable: :value,
      unique: :value,
      references: Poney.Model.ForeignKey
    ]

  @type t :: %__MODULE__{
          name: String.t(),
          type: String.t(),
          description: String.t() | nil,
          primary_key: boolean(),
          nullable: boolean(),
          unique: boolean(),
          references: Poney.Model.ForeignKey.t() | nil
        }
end
