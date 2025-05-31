defmodule AshSvg.AnimationState do
  @moduledoc """
  Tracks the current state of an animation in progress.
  
  This struct maintains all runtime information needed to calculate
  the current frame of an animation, including elapsed time, play state,
  and loop progress.
  """
  
  defstruct [
    :timeline,
    :status,
    :elapsed_time,
    :start_time,
    :pause_time,
    :current_loop,
    :current_direction,
    :last_frame_time,
    :current_values
  ]
  
  @type status :: :idle | :playing | :paused | :completed
  @type direction :: :forward | :backward
  
  @type t :: %__MODULE__{
    timeline: AshSvg.Timeline.t(),
    status: status(),
    elapsed_time: non_neg_integer(),
    start_time: non_neg_integer() | nil,
    pause_time: non_neg_integer() | nil,
    current_loop: non_neg_integer(),
    current_direction: direction(),
    last_frame_time: non_neg_integer() | nil,
    current_values: %{atom() => term()}
  }
  
  @doc """
  Creates a new animation state for the given timeline.
  """
  @spec new(AshSvg.Timeline.t()) :: t()
  def new(timeline) do
    %__MODULE__{
      timeline: timeline,
      status: :idle,
      elapsed_time: 0,
      start_time: nil,
      pause_time: nil,
      current_loop: 0,
      current_direction: :forward,
      last_frame_time: nil,
      current_values: %{}
    }
  end
  
  @doc """
  Starts the animation, setting the start time.
  """
  @spec start(t(), non_neg_integer()) :: t()
  def start(%__MODULE__{status: :idle} = state, current_time) do
    %{state | 
      status: :playing,
      start_time: current_time + state.timeline.delay,
      last_frame_time: current_time
    }
  end
  def start(%__MODULE__{status: :paused} = state, current_time) do
    # Resume from pause
    pause_duration = current_time - state.pause_time
    %{state | 
      status: :playing,
      start_time: state.start_time + pause_duration,
      pause_time: nil,
      last_frame_time: current_time
    }
  end
  def start(state, _current_time), do: state
  
  @doc """
  Pauses the animation at the current frame.
  """
  @spec pause(t(), non_neg_integer()) :: t()
  def pause(%__MODULE__{status: :playing} = state, current_time) do
    %{state | 
      status: :paused,
      pause_time: current_time
    }
  end
  def pause(state, _current_time), do: state
  
  @doc """
  Stops the animation and resets to the beginning.
  """
  @spec stop(t()) :: t()
  def stop(state) do
    %{state | 
      status: :idle,
      elapsed_time: 0,
      start_time: nil,
      pause_time: nil,
      current_loop: 0,
      current_direction: :forward,
      last_frame_time: nil,
      current_values: %{}
    }
  end
  
  @doc """
  Updates the animation state for the current time.
  
  Returns the updated state and the calculated property values for the current frame.
  """
  @spec update(t(), non_neg_integer()) :: {t(), %{atom() => term()}}
  def update(%__MODULE__{status: :playing} = state, current_time) do
    timeline = state.timeline
    
    # Calculate effective elapsed time
    elapsed = if state.start_time do
      max_value(0, current_time - state.start_time)
    else
      0
    end
    
    # Check if we've completed the animation
    {status, current_loop, elapsed, direction} = calculate_loop_state(
      elapsed, 
      timeline.duration, 
      timeline.loop_mode, 
      timeline.loop_count,
      state.current_loop,
      state.current_direction
    )
    
    # Calculate progress within current loop
    progress = calculate_progress(elapsed, timeline.duration, direction)
    
    # Interpolate values based on keyframes
    current_values = interpolate_timeline_values(timeline, progress)
    
    updated_state = %{state | 
      status: status,
      elapsed_time: elapsed,
      current_loop: current_loop,
      current_direction: direction,
      last_frame_time: current_time,
      current_values: current_values
    }
    
    {updated_state, current_values}
  end
  def update(state, _current_time), do: {state, state.current_values}
  
  @doc """
  Gets the current progress of the animation as a percentage (0.0 to 1.0).
  """
  @spec progress(t()) :: float()
  def progress(%__MODULE__{timeline: timeline, elapsed_time: elapsed}) do
    min_value(1.0, elapsed / timeline.duration)
  end
  
  @doc """
  Checks if the animation has completed.
  """
  @spec completed?(t()) :: boolean()
  def completed?(%__MODULE__{status: :completed}), do: true
  def completed?(_), do: false
  
  # Private functions
  
  defp calculate_loop_state(elapsed, duration, loop_mode, loop_count, current_loop, current_direction) do
    loops_completed = div(elapsed, duration)
    
    cond do
      # No looping
      loop_mode == :none and elapsed >= duration ->
        {:completed, 0, duration, :forward}
      
      # Finite looping completed
      loop_count != :infinite and loops_completed >= loop_count ->
        {:completed, loop_count - 1, duration, current_direction}
      
      # Still looping
      true ->
        case loop_mode do
          :restart ->
            loop_elapsed = rem(elapsed, duration)
            {:playing, loops_completed, loop_elapsed, :forward}
          
          :reverse ->
            loop_elapsed = rem(elapsed, duration)
            direction = if rem(loops_completed, 2) == 0, do: :forward, else: :backward
            {:playing, loops_completed, loop_elapsed, direction}
          
          :alternate ->
            loop_elapsed = rem(elapsed, duration)
            # Alternate changes direction smoothly
            direction = if rem(loops_completed, 2) == 0, do: :forward, else: :backward
            {:playing, loops_completed, loop_elapsed, direction}
          
          _ ->
            {:playing, current_loop, min_value(elapsed, duration), :forward}
        end
    end
  end
  
  defp calculate_progress(elapsed, duration, direction) do
    raw_progress = min_value(1.0, elapsed / duration)
    
    case direction do
      :forward -> raw_progress
      :backward -> 1.0 - raw_progress
    end
  end
  
  defp interpolate_timeline_values(timeline, progress) do
    keyframes = timeline.keyframes
    
    case length(keyframes) do
      0 -> %{}
      1 -> hd(keyframes).properties
      _ -> 
        # Find the two keyframes to interpolate between
        {from_kf, to_kf, segment_progress} = find_keyframe_segment(keyframes, progress)
        
        # Interpolate between them
        AshSvg.Keyframe.interpolate(from_kf, to_kf, segment_progress, timeline.easing)
    end
  end
  
  defp find_keyframe_segment(keyframes, progress) do
    sorted_keyframes = Enum.sort_by(keyframes, & &1.time)
    
    # Find the segment containing our progress
    {from_kf, to_kf} = sorted_keyframes
                      |> Enum.chunk_every(2, 1, :discard)
                      |> Enum.find({hd(sorted_keyframes), List.last(sorted_keyframes)}, fn [from, to] ->
                        progress >= from.time and progress <= to.time
                      end)
                      |> case do
                        [from, to] -> {from, to}
                        {from, to} -> {from, to}
                      end
    
    # Calculate progress within this segment
    segment_duration = to_kf.time - from_kf.time
    segment_progress = if segment_duration > 0 do
      (progress - from_kf.time) / segment_duration
    else
      0.0
    end
    
    {from_kf, to_kf, segment_progress}
  end
  
  defp max_value(a, b) when a > b, do: a
  defp max_value(_, b), do: b
  
  defp min_value(a, b) when a < b, do: a
  defp min_value(_, b), do: b
end