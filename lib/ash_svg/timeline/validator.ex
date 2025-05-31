defmodule AshSvg.Timeline.Validator do
  @moduledoc """
  Validation functions for timelines and keyframes.
  
  Ensures timeline consistency, keyframe ordering, and property compatibility.
  """
  
  alias AshSvg.{Timeline, Keyframe}
  
  @doc """
  Validates a complete timeline for consistency.
  
  Checks:
  - Keyframe times are within bounds (0.0 to 1.0)
  - Keyframes are properly ordered
  - All keyframes have consistent property sets
  - Property values are interpolatable between keyframes
  """
  @spec validate_timeline(Timeline.t()) :: :ok | {:error, term()}
  def validate_timeline(%Timeline{} = timeline) do
    with :ok <- validate_keyframe_times(timeline.keyframes),
         :ok <- validate_keyframe_ordering(timeline.keyframes),
         :ok <- validate_property_consistency(timeline.keyframes),
         :ok <- validate_property_interpolation(timeline.keyframes) do
      :ok
    end
  end
  
  @doc """
  Validates that all keyframe times are within valid bounds.
  """
  @spec validate_keyframe_times([Keyframe.t()]) :: :ok | {:error, term()}
  def validate_keyframe_times([]), do: :ok
  def validate_keyframe_times(keyframes) do
    invalid_times = keyframes
                   |> Enum.filter(fn kf -> kf.time < 0.0 or kf.time > 1.0 end)
                   |> Enum.map(& &1.time)
    
    if Enum.empty?(invalid_times) do
      :ok
    else
      {:error, {:invalid_keyframe_times, invalid_times}}
    end
  end
  
  @doc """
  Validates that keyframes are in chronological order.
  """
  @spec validate_keyframe_ordering([Keyframe.t()]) :: :ok | {:error, term()}
  def validate_keyframe_ordering([]), do: :ok
  def validate_keyframe_ordering([_]), do: :ok
  def validate_keyframe_ordering(keyframes) do
    sorted = Enum.sort_by(keyframes, & &1.time)
    
    if keyframes == sorted do
      # Check for duplicate times
      times = Enum.map(keyframes, & &1.time)
      unique_times = Enum.uniq(times)
      
      if length(times) == length(unique_times) do
        :ok
      else
        {:error, :duplicate_keyframe_times}
      end
    else
      {:error, :keyframes_not_ordered}
    end
  end
  
  @doc """
  Validates that all keyframes have consistent property sets.
  
  While properties can be added/removed between keyframes, this warns
  about potential issues with missing properties.
  """
  @spec validate_property_consistency([Keyframe.t()]) :: :ok | {:error, term()}
  def validate_property_consistency([]), do: :ok
  def validate_property_consistency([_]), do: :ok
  def validate_property_consistency(keyframes) do
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
      # This is a warning, not an error - interpolation will handle missing properties
      {:error, {:inconsistent_properties, inconsistencies}}
    end
  end
  
  @doc """
  Validates that property values can be interpolated between keyframes.
  """
  @spec validate_property_interpolation([Keyframe.t()]) :: :ok | {:error, term()}
  def validate_property_interpolation([]), do: :ok
  def validate_property_interpolation([_]), do: :ok
  def validate_property_interpolation(keyframes) do
    errors = keyframes
             |> Enum.chunk_every(2, 1, :discard)
             |> Enum.flat_map(fn [from_kf, to_kf] ->
               validate_keyframe_pair_interpolation(from_kf, to_kf)
             end)
    
    if Enum.empty?(errors) do
      :ok
    else
      {:error, {:interpolation_errors, errors}}
    end
  end
  
  @doc """
  Validates that a timeline can be composed with another timeline.
  """
  @spec validate_composition(Timeline.t(), Timeline.t(), atom()) :: :ok | {:error, term()}
  def validate_composition(timeline1, timeline2, mode) when mode in [:sequence, :parallel, :merge] do
    # For now, basic validation - can be extended
    cond do
      timeline1.duration == 0 -> {:error, :invalid_timeline1_duration}
      timeline2.duration == 0 -> {:error, :invalid_timeline2_duration}
      true -> :ok
    end
  end
  def validate_composition(_, _, mode) do
    {:error, {:invalid_composition_mode, mode}}
  end
  
  # Private functions
  
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