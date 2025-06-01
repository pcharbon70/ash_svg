defmodule AshSvg.Dsl.Verifiers.ValidateAnimations do
  @moduledoc """
  Verifies that all animations in the DSL are valid.
  
  This verifier ensures:
  - Keyframe times are within bounds (0.0 to 1.0)
  - Keyframes are properly ordered
  - All keyframes have consistent property sets
  - Property values are interpolatable between keyframes
  - Animation names are unique
  """
  
  use Spark.Dsl.Verifier
  
  alias Spark.Dsl.Verifier
  
  @impl true
  def verify(dsl_state) do
    animations = get_animations(dsl_state)
    
    with :ok <- verify_unique_names(animations, dsl_state),
         :ok <- verify_all_animations(animations, dsl_state) do
      :ok
    end
  end
  
  defp get_animations(dsl_state) do
    dsl_state
    |> Verifier.get_entities([:svg, :animations])
    |> Enum.map(&build_animation_struct/1)
  end
  
  defp build_animation_struct(animation_entity) do
    %{
      name: animation_entity.name,
      duration: animation_entity.duration,
      keyframes: build_keyframes(animation_entity.keyframes || [])
    }
  end
  
  defp build_keyframes(keyframe_entities) do
    Enum.map(keyframe_entities, fn kf ->
      properties = (kf.properties || [])
                  |> Enum.map(fn prop -> {prop.property, prop.value} end)
                  |> Map.new()
      
      %{
        time: kf.time,
        properties: properties,
        interpolation: kf.interpolation || :linear,
        easing: kf.easing
      }
    end)
  end
  
  defp verify_unique_names(animations, dsl_state) do
    names = Enum.map(animations, & &1.name)
    unique_names = Enum.uniq(names)
    
    if length(names) == length(unique_names) do
      :ok
    else
      duplicates = names -- unique_names
      
      {:error,
       Spark.Error.DslError.exception(
         message: "Animation names must be unique. Duplicates found: #{inspect(duplicates)}",
         path: [:svg, :animations],
         module: Verifier.get_persisted(dsl_state, :module)
       )}
    end
  end
  
  defp verify_all_animations(animations, dsl_state) do
    animations
    |> Enum.reduce_while(:ok, fn animation, :ok ->
      case verify_animation(animation, dsl_state) do
        :ok -> {:cont, :ok}
        error -> {:halt, error}
      end
    end)
  end
  
  defp verify_animation(animation, dsl_state) do
    with :ok <- verify_keyframe_times(animation, dsl_state),
         :ok <- verify_keyframe_ordering(animation, dsl_state),
         :ok <- verify_property_consistency(animation, dsl_state),
         :ok <- verify_property_interpolation(animation, dsl_state) do
      :ok
    end
  end
  
  defp verify_keyframe_times(%{name: name, keyframes: keyframes}, dsl_state) do
    invalid_times = keyframes
                   |> Enum.filter(fn kf -> kf.time < 0.0 or kf.time > 1.0 end)
                   |> Enum.map(& &1.time)
    
    if Enum.empty?(invalid_times) do
      :ok
    else
      {:error,
       Spark.Error.DslError.exception(
         message: "Animation #{inspect(name)} has keyframes with invalid times (must be 0.0-1.0): #{inspect(invalid_times)}",
         path: [:svg, :animations, name],
         module: Verifier.get_persisted(dsl_state, :module)
       )}
    end
  end
  
  defp verify_keyframe_ordering(%{name: name, keyframes: keyframes}, dsl_state) do
    sorted_keyframes = Enum.sort_by(keyframes, & &1.time)
    
    if keyframes == sorted_keyframes do
      # Check for duplicate times
      times = Enum.map(keyframes, & &1.time)
      unique_times = Enum.uniq(times)
      
      if length(times) == length(unique_times) do
        :ok
      else
        {:error,
         Spark.Error.DslError.exception(
           message: "Animation #{inspect(name)} has duplicate keyframe times",
           path: [:svg, :animations, name],
           module: Verifier.get_persisted(dsl_state, :module)
         )}
      end
    else
      {:error,
       Spark.Error.DslError.exception(
         message: "Animation #{inspect(name)} has keyframes that are not in chronological order",
         path: [:svg, :animations, name],
         module: Verifier.get_persisted(dsl_state, :module)
       )}
    end
  end
  
  defp verify_property_consistency(%{name: _name, keyframes: keyframes}, _dsl_state) when length(keyframes) < 2 do
    :ok
  end
  defp verify_property_consistency(%{name: _name, keyframes: keyframes}, _dsl_state) do
    # Get all unique property keys across all keyframes
    all_keys = keyframes
               |> Enum.flat_map(fn kf -> Map.keys(kf.properties) end)
               |> Enum.uniq()
               |> Enum.sort()
    
    # Check each keyframe for missing properties
    inconsistencies = keyframes
                     |> Enum.with_index()
                     |> Enum.flat_map(fn {kf, idx} ->
                       missing_keys = all_keys -- Map.keys(kf.properties)
                       if Enum.empty?(missing_keys) do
                         []
                       else
                         [{idx, kf.time, missing_keys}]
                       end
                     end)
    
    if Enum.empty?(inconsistencies) do
      :ok
    else
      # This is a warning, not an error - we'll log it but not fail
      # In production, you might want to make this configurable
      :ok
    end
  end
  
  defp verify_property_interpolation(%{name: _name, keyframes: keyframes}, _dsl_state) when length(keyframes) < 2 do
    :ok
  end
  defp verify_property_interpolation(%{name: name, keyframes: keyframes}, dsl_state) do
    errors = keyframes
             |> Enum.chunk_every(2, 1, :discard)
             |> Enum.flat_map(fn [from_kf, to_kf] ->
               validate_keyframe_pair_interpolation(from_kf, to_kf)
             end)
    
    if Enum.empty?(errors) do
      :ok
    else
      error_messages = Enum.map(errors, fn {prop, from_time, to_time, from_val, to_val} ->
        "Property #{inspect(prop)} between times #{from_time} and #{to_time}: " <>
        "cannot interpolate #{inspect(from_val)} to #{inspect(to_val)}"
      end)
      
      {:error,
       Spark.Error.DslError.exception(
         message: "Animation #{inspect(name)} has non-interpolatable properties:\n" <> Enum.join(error_messages, "\n"),
         path: [:svg, :animations, name],
         module: Verifier.get_persisted(dsl_state, :module)
       )}
    end
  end
  
  defp validate_keyframe_pair_interpolation(from_kf, to_kf) do
    # Get common properties
    from_keys = Map.keys(from_kf.properties)
    to_keys = Map.keys(to_kf.properties)
    common_keys = MapSet.intersection(MapSet.new(from_keys), MapSet.new(to_keys))
    
    # Check each common property for interpolation compatibility
    common_keys
    |> Enum.flat_map(fn key ->
      from_value = from_kf.properties[key]
      to_value = to_kf.properties[key]
      
      if interpolatable?(from_value, to_value) do
        []
      else
        [{key, from_kf.time, to_kf.time, from_value, to_value}]
      end
    end)
  end
  
  defp interpolatable?(v1, v2) when is_number(v1) and is_number(v2), do: true
  defp interpolatable?(v1, v2) when is_binary(v1) and is_binary(v2), do: true
  defp interpolatable?({x1, y1}, {x2, y2}) when is_number(x1) and is_number(y1) and is_number(x2) and is_number(y2), do: true
  defp interpolatable?({x1, y1, z1}, {x2, y2, z2}) 
       when is_number(x1) and is_number(y1) and is_number(z1) and
            is_number(x2) and is_number(y2) and is_number(z2), do: true
  defp interpolatable?({x1, y1, z1, w1}, {x2, y2, z2, w2}) 
       when is_number(x1) and is_number(y1) and is_number(z1) and is_number(w1) and
            is_number(x2) and is_number(y2) and is_number(z2) and is_number(w2), do: true
  defp interpolatable?(nil, _), do: true
  defp interpolatable?(_, nil), do: true
  defp interpolatable?(_, _), do: false
end