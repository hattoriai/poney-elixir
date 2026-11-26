defmodule Poney.Model.Step do
  @moduledoc """
  A step of an interaction, by its `"type"`: a message (`Poney.Model.Message`)
  or a combined fragment (`Poney.Model.Fragment`).
  """

  alias Poney.Model.{Fragment, Message}

  @type t :: Message.t() | Fragment.t()

  @doc false
  @spec from_json(map()) :: t()
  def from_json(%{"type" => "message"} = json), do: Message.from_json(json)
  def from_json(%{"type" => "fragment"} = json), do: Fragment.from_json(json)
end
