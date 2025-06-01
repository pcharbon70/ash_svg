defmodule AshSvg.Dsl.PropertySetter do
  @moduledoc """
  Represents a property setter in a keyframe.
  
  This struct is the target for the set entity and holds
  a property name and its value at a specific keyframe.
  """
  
  defstruct [
    :property,
    :value
  ]
  
  @type t :: %__MODULE__{
    property: atom(),
    value: any()
  }
end