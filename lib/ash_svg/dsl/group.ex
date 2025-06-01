defmodule AshSvg.Dsl.Group do
  @moduledoc """
  Represents a group element in the SVG DSL.
  
  Groups can contain other SVG elements including nested groups.
  """
  
  defstruct [
    :name,
    :fill,
    :stroke,
    :stroke_width,
    :opacity,
    :transform,
    :class,
    :id,
    :style,
    elements: []
  ]
  
  @type element :: AshSvg.Dsl.Circle.t() | AshSvg.Dsl.Rect.t() | 
                  AshSvg.Dsl.Path.t() | t()
  
  @type t :: %__MODULE__{
    name: atom(),
    fill: String.t() | nil,
    stroke: String.t() | nil,
    stroke_width: number() | nil,
    opacity: number() | nil,
    transform: String.t() | nil,
    class: String.t() | nil,
    id: String.t() | nil,
    style: String.t() | nil,
    elements: [element()]
  }
end