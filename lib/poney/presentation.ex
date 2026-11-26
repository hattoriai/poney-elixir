defmodule Poney.Presentation do
  @moduledoc """
  How things look (§7), apart from what they mean: a style for each entity
  kind and relationship kind, and overrides by element and by view.
  """

  use Poney.Struct,
    fields: [
      kinds: {:map, Poney.Presentation.KindStyle},
      relationships: {:map, Poney.Presentation.LineStyle},
      elements: {:map, Poney.Presentation.Override},
      views: {:map, {:map, Poney.Presentation.Override}}
    ]

  @type t :: %__MODULE__{
          kinds: %{optional(String.t()) => Poney.Presentation.KindStyle.t()},
          relationships: %{optional(String.t()) => Poney.Presentation.LineStyle.t()},
          elements: %{optional(String.t()) => Poney.Presentation.Override.t()},
          views: %{
            optional(String.t()) => %{optional(String.t()) => Poney.Presentation.Override.t()}
          }
        }
end
