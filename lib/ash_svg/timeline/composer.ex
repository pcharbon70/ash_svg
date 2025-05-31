defmodule AshSvg.Timeline.Composer do
  @moduledoc """
  Functions for composing multiple timelines together.
  
  Supports merging, sequencing, and parallel composition of timelines
  to create complex animation sequences.
  """
  
  alias AshSvg.{Timeline, Keyframe}
  alias AshSvg.Timeline.Validator
  
  @doc """
  Merges two timelines, combining their keyframes.
  
  The resulting timeline has the longer duration of the two,
  and keyframes from both timelines are combined.
  """
  @spec merge(Timeline.t(), Timeline.t(), keyword()) :: {:ok, Timeline.t()} | {:error, term()}
  def merge(timeline1, timeline2, opts \\ []) do
    with :ok <- Validator.validate_composition(timeline1, timeline2, :merge) do
      duration = max_value(timeline1.duration, timeline2.duration)
      
      # Convert absolute times if needed
      kf1_normalized = normalize_keyframes(timeline1.keyframes, timeline1.duration, duration)
      kf2_normalized = normalize_keyframes(timeline2.keyframes, timeline2.duration, duration)
      
      # Merge keyframes
      merged_keyframes = merge_keyframes(kf1_normalized, kf2_normalized, opts)
      
      Timeline.new(
        duration: duration,
        keyframes: merged_keyframes,
        easing: opts[:easing] || timeline1.easing,
        loop_mode: opts[:loop_mode] || :none,
        loop_count: opts[:loop_count] || 1
      )
    end
  end
  
  @doc """
  Creates a sequence of timelines that play one after another.
  
  The resulting timeline duration is the sum of all timeline durations.
  """
  @spec sequence([Timeline.t()], keyword()) :: {:ok, Timeline.t()} | {:error, term()}
  def sequence(timelines, opts \\ [])
  def sequence([], _opts), do: {:error, :empty_timeline_list}
  def sequence([timeline], _opts), do: {:ok, timeline}
  def sequence(timelines, opts) do
    # Validate all timelines
    validation_results = Enum.map(timelines, fn tl -> 
      Validator.validate_timeline(tl)
    end)
    
    case Enum.find(validation_results, &(&1 != :ok)) do
      nil ->
        # Calculate total duration
        total_duration = timelines
                        |> Enum.map(& &1.duration)
                        |> Enum.sum()
        
        # Build sequenced keyframes
        {sequenced_keyframes, _} = timelines
                                   |> Enum.reduce({[], 0}, fn timeline, {keyframes_acc, time_offset} ->
                                     # Adjust keyframe times to account for offset
                                     adjusted_keyframes = timeline.keyframes
                                                         |> Enum.map(fn kf ->
                                                           time_in_sequence = (kf.time * timeline.duration + time_offset) / total_duration
                                                           %{kf | time: time_in_sequence}
                                                         end)
                                     
                                     {keyframes_acc ++ adjusted_keyframes, time_offset + timeline.duration}
                                   end)
        
        Timeline.new(
          duration: total_duration,
          keyframes: sequenced_keyframes,
          easing: opts[:easing] || :linear,
          loop_mode: opts[:loop_mode] || :none,
          loop_count: opts[:loop_count] || 1
        )
      
      error ->
        error
    end
  end
  
  @doc """
  Creates parallel timelines that play simultaneously.
  
  The resulting timeline duration is the longest of all timelines.
  Different property sets are preserved.
  """
  @spec parallel([Timeline.t()], keyword()) :: {:ok, Timeline.t()} | {:error, term()}
  def parallel(timelines, opts \\ [])
  def parallel([], _opts), do: {:error, :empty_timeline_list}
  def parallel([timeline], _opts), do: {:ok, timeline}
  def parallel(timelines, opts) do
    # Find the longest duration
    max_duration = timelines
                  |> Enum.map(& &1.duration)
                  |> Enum.max()
    
    # Normalize all timelines to the same duration
    normalized_timelines = Enum.map(timelines, fn tl ->
      normalize_keyframes(tl.keyframes, tl.duration, max_duration)
    end)
    
    # Merge all keyframes
    merged_keyframes = normalized_timelines
                      |> Enum.reduce([], fn keyframes, acc ->
                        merge_keyframes(acc, keyframes, opts)
                      end)
    
    Timeline.new(
      duration: max_duration,
      keyframes: merged_keyframes,
      easing: opts[:easing] || :linear,
      loop_mode: opts[:loop_mode] || :none,
      loop_count: opts[:loop_count] || 1
    )
  end
  
  @doc """
  Reverses a timeline, playing it backwards.
  """
  @spec reverse(Timeline.t()) :: {:ok, Timeline.t()} | {:error, term()}
  def reverse(%Timeline{} = timeline) do
    reversed_keyframes = timeline.keyframes
                        |> Enum.map(fn kf ->
                          %{kf | time: 1.0 - kf.time}
                        end)
                        |> Enum.reverse()
    
    Timeline.new(
      duration: timeline.duration,
      keyframes: reversed_keyframes,
      easing: reverse_easing(timeline.easing),
      loop_mode: timeline.loop_mode,
      loop_count: timeline.loop_count
    )
  end
  
  @doc """
  Scales a timeline's duration by a factor.
  """
  @spec scale(Timeline.t(), float()) :: {:ok, Timeline.t()} | {:error, term()}
  def scale(%Timeline{} = timeline, factor) when factor > 0 do
    Timeline.new(
      duration: round(timeline.duration * factor),
      keyframes: timeline.keyframes,
      easing: timeline.easing,
      loop_mode: timeline.loop_mode,
      loop_count: timeline.loop_count
    )
  end
  def scale(_, _), do: {:error, :invalid_scale_factor}
  
  @doc """
  Repeats a timeline a specified number of times.
  """
  @spec repeat(Timeline.t(), pos_integer() | :infinite) :: {:ok, Timeline.t()} | {:error, term()}
  def repeat(%Timeline{} = timeline, count) when is_integer(count) and count > 0 do
    {:ok, %{timeline | loop_mode: :restart, loop_count: count}}
  end
  def repeat(%Timeline{} = timeline, :infinite) do
    {:ok, %{timeline | loop_mode: :restart, loop_count: :infinite}}
  end
  def repeat(_, _), do: {:error, :invalid_repeat_count}
  
  # Private helper functions
  
  defp normalize_keyframes(keyframes, original_duration, target_duration) do
    duration_ratio = original_duration / target_duration
    
    Enum.map(keyframes, fn kf ->
      %{kf | time: kf.time * duration_ratio}
    end)
  end
  
  defp merge_keyframes(keyframes1, keyframes2, opts) do
    merge_strategy = Keyword.get(opts, :merge_strategy, :combine)
    
    case merge_strategy do
      :combine ->
        # Combine all keyframes, merging properties at the same time
        all_keyframes = keyframes1 ++ keyframes2
        
        all_keyframes
        |> Enum.group_by(& &1.time)
        |> Enum.map(fn {time, keyframes_at_time} ->
          # Merge properties from all keyframes at this time
          merged_properties = keyframes_at_time
                             |> Enum.map(& &1.properties)
                             |> Enum.reduce(%{}, &Map.merge(&2, &1))
          
          # Use the last keyframe's interpolation settings
          last_kf = List.last(keyframes_at_time)
          
          %Keyframe{
            time: time,
            properties: merged_properties,
            easing: last_kf.easing,
            interpolation_mode: last_kf.interpolation_mode
          }
        end)
        |> Enum.sort_by(& &1.time)
      
      :override ->
        # keyframes2 overrides keyframes1
        keyframes2
      
      _ ->
        keyframes1 ++ keyframes2
    end
  end
  
  defp reverse_easing(:ease_in), do: :ease_out
  defp reverse_easing(:ease_out), do: :ease_in
  defp reverse_easing(easing), do: easing
  
  defp max_value(a, b) when a > b, do: a
  defp max_value(_, b), do: b
end