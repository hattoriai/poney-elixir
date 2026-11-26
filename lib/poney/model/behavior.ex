defmodule Poney.Model.Behavior do
  @moduledoc """
  A behavior (§5.6), by its `"kind"`: an interaction (`Poney.Model.Interaction`),
  an activity (`Poney.Model.Activity`) or a state machine
  (`Poney.Model.StateMachine`).
  """

  alias Poney.Model.{Activity, Interaction, StateMachine}

  @type t :: Interaction.t() | Activity.t() | StateMachine.t()

  @doc false
  @spec from_json(map()) :: t()
  def from_json(%{"kind" => "interaction"} = json), do: Interaction.from_json(json)
  def from_json(%{"kind" => "activity"} = json), do: Activity.from_json(json)
  def from_json(%{"kind" => "state-machine"} = json), do: StateMachine.from_json(json)
end
