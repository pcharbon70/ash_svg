defmodule AshSvg.Dsl.Rect do
  @moduledoc """
  Represents a rectangle element in the SVG DSL.
  """
  
  defstruct [
    :name,
    :x,
    :y,
    :width,
    :height,
    :rx,
    :ry,
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
    x: number(),
    y: number(),
    width: number(),
    height: number(),
    rx: number() | nil,
    ry: number() | nil,
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