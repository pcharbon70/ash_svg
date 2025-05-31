defmodule AshSvg.Timeline do
  @moduledoc """
  Core timeline data structure for AshSvg animations.
  
  A timeline represents a complete animation sequence with keyframes,
  duration, and easing configuration.
  """
  
  defstruct [
    :id,
    :duration,
    :keyframes,
    :easing,
    :loop_mode,
    :loop_count,
    :delay,
    :metadata
  ]
  
  @type easing_function :: :linear | :ease_in | :ease_out | :ease_in_out | 
                          {:cubic_bezier, float(), float(), float(), float()} |
                          {:custom, (float() -> float())}
  
  @type loop_mode :: :none | :restart | :reverse | :alternate
  
  @type t :: %__MODULE__{
    id: String.t() | nil,
    duration: non_neg_integer(),
    keyframes: [AshSvg.Keyframe.t()],
    easing: easing_function(),
    loop_mode: loop_mode(),
    loop_count: non_neg_integer() | :infinite,
    delay: non_neg_integer(),
    metadata: map()
  }
  
  @doc """
  Creates a new timeline with the given options.
  
  ## Options
  
    * `:id` - Optional unique identifier for the timeline
    * `:duration` - Total duration in milliseconds (required)
    * `:keyframes` - List of keyframes (default: [])
    * `:easing` - Easing function (default: :linear)
    * `:loop_mode` - How to loop the animation (default: :none)
    * `:loop_count` - Number of times to loop (default: 1)
    * `:delay` - Delay before starting in milliseconds (default: 0)
    * `:metadata` - Additional metadata (default: %{})
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, term()}
  def new(opts) do
    with {:ok, duration} <- validate_duration(opts[:duration]),
         {:ok, keyframes} <- validate_keyframes(opts[:keyframes] || []),
         {:ok, easing} <- validate_easing(opts[:easing] || :linear),
         {:ok, loop_mode} <- validate_loop_mode(opts[:loop_mode] || :none),
         {:ok, loop_count} <- validate_loop_count(opts[:loop_count] || 1),
         {:ok, delay} <- validate_delay(opts[:delay] || 0) do
      {:ok, %__MODULE__{
        id: opts[:id],
        duration: duration,
        keyframes: keyframes,
        easing: easing,
        loop_mode: loop_mode,
        loop_count: loop_count,
        delay: delay,
        metadata: opts[:metadata] || %{}
      }}
    end
  end
  
  @doc """
  Creates a new timeline, raising on error.
  """
  @spec new!(keyword()) :: t()
  def new!(opts) do
    case new(opts) do
      {:ok, timeline} -> timeline
      {:error, reason} -> raise ArgumentError, "Invalid timeline: #{inspect(reason)}"
    end
  end
  
  # Validation functions
  
  defp validate_duration(nil), do: {:error, :duration_required}
  defp validate_duration(duration) when is_integer(duration) and duration > 0, do: {:ok, duration}
  defp validate_duration(_), do: {:error, :invalid_duration}
  
  defp validate_keyframes(keyframes) when is_list(keyframes), do: {:ok, keyframes}
  defp validate_keyframes(_), do: {:error, :invalid_keyframes}
  
  defp validate_easing(:linear), do: {:ok, :linear}
  defp validate_easing(:ease_in), do: {:ok, :ease_in}
  defp validate_easing(:ease_out), do: {:ok, :ease_out}
  defp validate_easing(:ease_in_out), do: {:ok, :ease_in_out}
  defp validate_easing({:cubic_bezier, x1, y1, x2, y2} = bezier) 
       when is_float(x1) and is_float(y1) and is_float(x2) and is_float(y2) do
    {:ok, bezier}
  end
  defp validate_easing({:custom, func}) when is_function(func, 1), do: {:ok, {:custom, func}}
  defp validate_easing(_), do: {:error, :invalid_easing}
  
  defp validate_loop_mode(mode) when mode in [:none, :restart, :reverse, :alternate], do: {:ok, mode}
  defp validate_loop_mode(_), do: {:error, :invalid_loop_mode}
  
  defp validate_loop_count(:infinite), do: {:ok, :infinite}
  defp validate_loop_count(count) when is_integer(count) and count >= 0, do: {:ok, count}
  defp validate_loop_count(_), do: {:error, :invalid_loop_count}
  
  defp validate_delay(delay) when is_integer(delay) and delay >= 0, do: {:ok, delay}
  defp validate_delay(_), do: {:error, :invalid_delay}
end