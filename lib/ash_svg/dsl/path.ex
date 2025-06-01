defmodule AshSvg.Dsl.Path do
  @moduledoc """
  Represents a path element in the SVG DSL.
  """
  
  defstruct [
    :name,
    :d,
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
    d: String.t(),
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