defmodule Poney.Model do
  @moduledoc """
  The semantic model (§5): what the software is, independent of any diagram.
  """

  use Poney.Struct,
    fields: [
      entities: {:list, Poney.Model.Entity},
      relationships: {:list, Poney.Model.Relationship},
      data_types: {:list, Poney.Model.DataType},
      data_relations: {:list, Poney.Model.DataRelation},
      data_flows: {:list, Poney.Model.DataFlow},
      behaviors: {:list, Poney.Model.Behavior},
      use_cases: {:list, Poney.Model.UseCase}
    ]

  @type t :: %__MODULE__{
          entities: [Poney.Model.Entity.t()],
          relationships: [Poney.Model.Relationship.t()],
          data_types: [Poney.Model.DataType.t()],
          data_relations: [Poney.Model.DataRelation.t()],
          data_flows: [Poney.Model.DataFlow.t()],
          behaviors: [Poney.Model.Behavior.t()],
          use_cases: [Poney.Model.UseCase.t()]
        }
end
