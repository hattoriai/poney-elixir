defmodule Poney.Walkthrough.Source do
  @moduledoc """
  Where a change or a tour comes from: a merge request, a commit, a repository.
  """

  use Poney.Struct,
    fields: [
      kind: :value,
      ref: :value,
      head: :value,
      url: :value,
      repository: :value,
      base: :value,
      author: :value,
      files: :value,
      added: :value,
      removed: :value
    ]

  @type t :: %__MODULE__{
          kind: String.t(),
          ref: String.t() | nil,
          head: String.t() | nil,
          url: String.t() | nil,
          repository: String.t() | nil,
          base: String.t() | nil,
          author: String.t() | nil,
          files: non_neg_integer() | nil,
          added: non_neg_integer() | nil,
          removed: non_neg_integer() | nil
        }
end
