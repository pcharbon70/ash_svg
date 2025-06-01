defmodule AshSvg.Dsl.Keyframe do
  @moduledoc """
  Represents a keyframe definition in the DSL.
  
  This struct is the target for the keyframe entity and holds
  the properties and timing information for a single keyframe.
  """
  
  defstruct [
    :time,
    :interpolation,
    :easing,
    properties: []
  ]
  
  @type t :: %__MODULE__{
    time: float(),
    interpolation: atom(),
    easing: atom() | nil,
    properties: [AshSvg.Dsl.PropertySetter.t()]
  }
end