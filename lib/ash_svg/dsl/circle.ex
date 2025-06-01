defmodule AshSvg.Dsl.Circle do
  @moduledoc """
  Represents a circle element in the SVG DSL.
  """
  
  defstruct [
    :name,
    :cx,
    :cy,
    :r,
    :fill,
    :stroke,
    :stroke_width,
    :opacity,
    :transform,
    :class,
    :id,
    :style
  ]
  
  @type t :: %__MODULE__{
    name: atom(),
    cx: number(),
    cy: number(),
    r: number(),
    fill: String.t() | nil,
    stroke: String.t() | nil,
    stroke_width: number() | nil,
    opacity: number() | nil,
    transform: String.t() | nil,
    class: String.t() | nil,
    id: String.t() | nil,
    style: String.t() | nil
  }
end