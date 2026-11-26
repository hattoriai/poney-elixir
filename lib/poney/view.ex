defmodule Poney.View do
  @moduledoc """
  A view (§6): which part of the model one diagram shows, and how it is
  organized. Each type has its own struct; `type` holds the format's name
  for it.

  | `type`           | Struct                     |
  |------------------|----------------------------|
  | `"architecture"` | `Poney.View.Architecture`  |
  | `"map"`          | `Poney.View.Map`           |
  | `"sequence"`     | `Poney.View.Sequence`      |
  | `"dataflow"`     | `Poney.View.DataFlow`      |
  | `"activity"`     | `Poney.View.Activity`      |
  | `"erd"`          | `Poney.View.Erd`           |
  | `"state"`        | `Poney.View.State`         |
  | `"usecase"`      | `Poney.View.UseCase`       |
  | `"dependency"`   | `Poney.View.Dependency`    |
  | `"extension"`    | `Poney.View.Extension`     |
  """

  @type t ::
          Poney.View.Architecture.t()
          | Poney.View.Map.t()
          | Poney.View.Sequence.t()
          | Poney.View.DataFlow.t()
          | Poney.View.Activity.t()
          | Poney.View.Erd.t()
          | Poney.View.State.t()
          | Poney.View.UseCase.t()
          | Poney.View.Dependency.t()
          | Poney.View.Extension.t()

  @types %{
    "architecture" => Poney.View.Architecture,
    "map" => Poney.View.Map,
    "sequence" => Poney.View.Sequence,
    "dataflow" => Poney.View.DataFlow,
    "activity" => Poney.View.Activity,
    "erd" => Poney.View.Erd,
    "state" => Poney.View.State,
    "usecase" => Poney.View.UseCase,
    "dependency" => Poney.View.Dependency,
    "extension" => Poney.View.Extension
  }

  @doc false
  @spec from_json(map()) :: t()
  def from_json(%{"type" => type} = json), do: Map.fetch!(@types, type).from_json(json)
end
