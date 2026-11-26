defmodule Poney.Document do
  @moduledoc """
  A Poney document in its canonical form (§3): one model of a system, its
  views, its walkthroughs and its presentation. Every default is filled in,
  and views written inside walkthrough scenes are in `views`, so a scene's
  `view` is always the id of one.
  """

  use Poney.Struct,
    fields: [
      poney_version: :value,
      project: Poney.Project,
      extensions: {:list, Poney.ExtensionUse},
      model: Poney.Model,
      views: {:list, Poney.View},
      walkthroughs: {:list, Poney.Walkthrough},
      presentation: Poney.Presentation
    ]

  @type t :: %__MODULE__{
          poney_version: String.t(),
          project: Poney.Project.t(),
          extensions: [Poney.ExtensionUse.t()],
          model: Poney.Model.t(),
          views: [Poney.View.t()],
          walkthroughs: [Poney.Walkthrough.t()],
          presentation: Poney.Presentation.t()
        }
end
