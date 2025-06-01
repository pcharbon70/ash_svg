defmodule AshSvg.Dsl do
  @moduledoc """
  The Spark DSL extension for AshSvg animations.
  
  This extension provides a declarative way to define animations, timelines,
  and keyframes using Spark's DSL capabilities.
  """
  
  alias AshSvg.Dsl.Entities
  
  @svg_section %Spark.Dsl.Section{
    name: :svg,
    describe: "Defines the different elements of an SVG.",
    entities: Entities.svg_elements(),
    sections: [
      Entities.animations_section()
    ]
  }
  
  use Spark.Dsl.Extension,
    sections: [@svg_section],
    transformers: [
      AshSvg.Dsl.Transformers.CollectElements,
      AshSvg.Dsl.Transformers.BuildTimelines
    ],
    verifiers: [
      AshSvg.Dsl.Verifiers.ValidateAnimations,
      AshSvg.Dsl.Verifiers.ValidateAnimationTargets
    ]
end