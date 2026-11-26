defmodule Poney.Walkthrough.Verdict do
  @moduledoc """
  The reviewer's verdict: a risk (`"look"` or `"routine"`), facts, and findings.
  """

  use Poney.Struct,
    fields: [
      risk: :value,
      facts: {:list, Poney.Walkthrough.Fact},
      findings: {:list, Poney.Walkthrough.Finding}
    ]

  @type t :: %__MODULE__{
          risk: String.t(),
          facts: [Poney.Walkthrough.Fact.t()],
          findings: [Poney.Walkthrough.Finding.t()]
        }
end
