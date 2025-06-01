defmodule AshSvg.Dsl.Transformers.BuildTimelines do
  @moduledoc """
  Transforms DSL animation definitions into Timeline structs.
  
  This transformer takes the animations defined in the DSL and converts
  them into the internal Timeline representation used by the animation engine.
  """
  
  use Spark.Dsl.Transformer
  
  alias Spark.Dsl.Transformer
  alias AshSvg.{Timeline, Keyframe}
  
  @impl true
  def transform(dsl_state) do
    animations = dsl_state
                |> Transformer.get_entities([:svg, :animations])
                |> Enum.map(&build_timeline/1)
    
    # Store the built timelines for later use
    dsl_state = Transformer.persist(dsl_state, :timelines, animations)
    
    {:ok, dsl_state}
  end
  
  defp build_timeline(animation_entity) do
    keyframes = animation_entity.keyframes
                |> Enum.map(&build_keyframe/1)
                |> Enum.sort_by(& &1.time)
    
    timeline_opts = [
      duration: animation_entity.duration,
      keyframes: keyframes,
      easing: animation_entity.easing || :linear,
      loop_mode: animation_entity.loop_mode || :none,
      loop_count: animation_entity.loop_count || 1,
      delay: animation_entity.delay || 0
    ]
    
    case Timeline.new(timeline_opts) do
      {:ok, timeline} -> 
        # Add target to the timeline metadata
        timeline_with_target = %{timeline | metadata: Map.put(timeline.metadata, :target, animation_entity.target)}
        {animation_entity.name, timeline_with_target}
      {:error, reason} ->
        raise Spark.Error.DslError,
          message: "Failed to build timeline for animation #{inspect(animation_entity.name)}: #{inspect(reason)}",
          path: [:animations, animation_entity.name]
    end
  end
  
  defp build_keyframe(keyframe_entity) do
    properties = keyframe_entity.properties
                |> Enum.map(fn prop -> {prop.property, prop.value} end)
                |> Map.new()
    
    keyframe_opts = [
      time: keyframe_entity.time,
      properties: properties,
      interpolation_mode: keyframe_entity.interpolation || :linear,
      easing: keyframe_entity.easing
    ]
    
    case Keyframe.new(keyframe_opts) do
      {:ok, keyframe} -> keyframe
      {:error, reason} ->
        raise Spark.Error.DslError,
          message: "Failed to build keyframe at time #{keyframe_entity.time}: #{inspect(reason)}",
          path: [:animations]
    end
  end
  
  # Control execution order
  @impl true
  def after?(_), do: false
  
  @impl true
  def before?(_), do: true
end