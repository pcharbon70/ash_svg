defmodule AshSvg.Dsl.Animation do
  @moduledoc """
  Represents an animation definition in the DSL.
  
  This struct is the target for the animation entity and holds
  all the configuration for a single animation.
  """
  
  defstruct [
    :name,
    :target,
    :duration,
    :easing,
    :loop_mode,
    :loop_count,
    :delay,
    keyframes: []
  ]
  
  @type t :: %__MODULE__{
    name: atom(),
    target: atom() | nil,
    duration: pos_integer(),
    easing: atom(),
    loop_mode: atom(),
    loop_count: pos_integer() | :infinite,
    delay: non_neg_integer(),
    keyframes: [AshSvg.Dsl.Keyframe.t()]
  }
end