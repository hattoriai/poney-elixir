defmodule Poney.Ref do
  @moduledoc """
  A reference to one element of a document, as walkthroughs write it
  (§5.8): `"<kind>:<id>"`, `"<kind>:<behavior>:<id>"` for the parts of a
  behavior, `"group:<view>:<id>"` for a group of a view, and
  `"dataType:<id>#<field>"` for a field.

      iex> Poney.Ref.parse("transition:order-lifecycle:t-retry")
      {:ok, %Poney.Ref{kind: :transition, behavior: "order-lifecycle", id: "t-retry"}}

      iex> to_string(%Poney.Ref{kind: :data_type, id: "orders", field: "status"})
      "dataType:orders#status"

  Kinds are atoms in snake case (`:data_type`, `:use_case`); the text form
  keeps the format's names (`dataType`, `useCase`).
  """

  @type kind ::
          :entity
          | :relationship
          | :use_case
          | :data_flow
          | :data_relation
          | :behavior
          | :data_type
          | :group
          | :message
          | :fragment
          | :state
          | :transition
          | :activity_node
          | :activity_flow

  @type t :: %__MODULE__{
          kind: kind(),
          id: String.t(),
          behavior: String.t() | nil,
          view: String.t() | nil,
          field: String.t() | nil
        }

  @enforce_keys [:kind, :id]
  defstruct [:kind, :id, :behavior, :view, :field]

  @simple %{
    "entity" => :entity,
    "relationship" => :relationship,
    "useCase" => :use_case,
    "dataFlow" => :data_flow,
    "dataRelation" => :data_relation,
    "behavior" => :behavior
  }
  @in_behavior %{
    "message" => :message,
    "fragment" => :fragment,
    "state" => :state,
    "transition" => :transition,
    "activityNode" => :activity_node,
    "activityFlow" => :activity_flow
  }
  @names Map.new(Map.merge(@simple, @in_behavior), fn {name, kind} -> {kind, name} end)

  @doc "Parses a ref key. Text that is not a ref gives `:error`."
  @spec parse(String.t()) :: {:ok, t()} | :error
  def parse(text) when is_binary(text) do
    case String.split(text, ":") do
      [_kind] -> :error
      [kind | rest] -> parse(kind, rest)
    end
  end

  defp parse(kind, rest) when is_map_key(@simple, kind) do
    with_id(Enum.join(rest, ":"), &%__MODULE__{kind: @simple[kind], id: &1})
  end

  defp parse("dataType", rest) do
    case rest |> Enum.join(":") |> String.split("#", parts: 2) do
      [""] -> :error
      [id] -> {:ok, %__MODULE__{kind: :data_type, id: id}}
      [id, ""] -> {:ok, %__MODULE__{kind: :data_type, id: id}}
      [id, field] -> {:ok, %__MODULE__{kind: :data_type, id: id, field: field}}
    end
  end

  defp parse("group", [view | id]) when id != [] do
    {:ok, %__MODULE__{kind: :group, view: view, id: Enum.join(id, ":")}}
  end

  defp parse(kind, [behavior | id]) when is_map_key(@in_behavior, kind) and id != [] do
    {:ok, %__MODULE__{kind: @in_behavior[kind], behavior: behavior, id: Enum.join(id, ":")}}
  end

  defp parse(_kind, _rest), do: :error

  defp with_id("", _make), do: :error
  defp with_id(id, make), do: {:ok, make.(id)}

  @doc "The text form of a ref."
  @spec key(t()) :: String.t()
  def key(%__MODULE__{kind: :data_type, id: id, field: nil}), do: "dataType:#{id}"
  def key(%__MODULE__{kind: :data_type, id: id, field: field}), do: "dataType:#{id}##{field}"
  def key(%__MODULE__{kind: :group, view: view, id: id}), do: "group:#{view}:#{id}"
  def key(%__MODULE__{kind: kind, behavior: nil, id: id}), do: "#{@names[kind]}:#{id}"

  def key(%__MODULE__{kind: kind, behavior: behavior, id: id}),
    do: "#{@names[kind]}:#{behavior}:#{id}"

  defimpl String.Chars do
    def to_string(ref), do: Poney.Ref.key(ref)
  end
end
