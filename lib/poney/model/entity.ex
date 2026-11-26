defmodule Poney.Model.Entity do
  @moduledoc """
  A part of the software (§5.1): a person, a system, a service, a database…
  `kind` is a core kind such as `"service"`, or an extension's, such as
  `"ownership/team"`. `parent` names the entity it is inside.
  """

  use Poney.Struct,
    fields: [
      id: :value,
      kind: :value,
      name: :value,
      summary: :value,
      description: :value,
      parent: :value,
      technology: :value,
      tags: :value,
      source_refs: {:list, Poney.Model.SourceRef},
      metadata: :value,
      ext: :value
    ]

  @type t :: %__MODULE__{
          id: String.t(),
          kind: String.t(),
          name: String.t(),
          summary: String.t(),
          description: String.t() | nil,
          parent: String.t() | nil,
          technology: String.t() | nil,
          tags: [String.t()],
          source_refs: [Poney.Model.SourceRef.t()],
          metadata: %{optional(String.t()) => String.t() | number() | boolean()},
          ext: %{optional(String.t()) => term()}
        }
end
