defmodule Poney.InvalidDocumentError do
  @moduledoc "Raised by `Poney.read!/1` when a document has errors. `issues` lists them all."

  defexception issues: []

  @type t :: %__MODULE__{issues: [Poney.Issue.t()]}

  @impl true
  def message(%{issues: issues}) do
    errors = Enum.filter(issues, &(&1.severity == :error))
    first = List.first(errors)
    more = if length(errors) > 1, do: " (and #{length(errors) - 1} more)", else: ""
    "Invalid Poney document: #{first}#{more}"
  end
end
