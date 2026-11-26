defmodule Poney.Issue do
  @moduledoc """
  One problem in a document.

  An error makes the document invalid; a warning is information for the
  author. `path` names the value, as the specification writes it (§9.4):
  member names and array indexes joined by dots, from the root, for example
  `"model.relationships.4.target"`. `hint` says how to fix it, when the
  reader can tell.
  """

  @type severity :: :error | :warning

  @type t :: %__MODULE__{
          path: String.t(),
          message: String.t(),
          severity: severity(),
          hint: String.t() | nil
        }

  @enforce_keys [:path, :message, :severity]
  defstruct [:path, :message, :severity, :hint]

  @doc false
  @spec error(String.t(), String.t(), String.t() | nil) :: t()
  def error(path, message, hint \\ nil),
    do: %__MODULE__{path: path, message: message, severity: :error, hint: hint}

  @doc false
  @spec warning(String.t(), String.t(), String.t() | nil) :: t()
  def warning(path, message, hint \\ nil),
    do: %__MODULE__{path: path, message: message, severity: :warning, hint: hint}

  @doc false
  @spec path([String.t() | non_neg_integer()]) :: String.t()
  def path(segments), do: Enum.map_join(segments, ".", &to_string/1)

  defimpl String.Chars do
    def to_string(%{path: "", message: message}), do: message
    def to_string(%{path: path, message: message}), do: "#{path}: #{message}"
  end
end
