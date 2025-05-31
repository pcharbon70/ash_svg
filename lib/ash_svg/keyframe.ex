defmodule AshSvg.Keyframe do
  @moduledoc """
  Represents a single keyframe in an animation timeline.
  
  A keyframe defines the state of animated properties at a specific 
  point in time, along with interpolation settings for transitioning
  to the next keyframe.
  """
  
  defstruct [
    :time,
    :properties,
    :easing,
    :interpolation_mode
  ]
  
  @type interpolation_mode :: :linear | :discrete | :spline | :hold
  
  @type property_value :: number() | String.t() | {number(), number()} | 
                         {number(), number(), number()} | 
                         {number(), number(), number(), number()}
  
  @type t :: %__MODULE__{
    time: float(),
    properties: %{atom() => property_value()},
    easing: AshSvg.Timeline.easing_function() | nil,
    interpolation_mode: interpolation_mode()
  }
  
  @doc """
  Creates a new keyframe.
  
  ## Options
  
    * `:time` - Time position as a percentage (0.0 to 1.0) or milliseconds
    * `:properties` - Map of property names to values
    * `:easing` - Optional easing function for this keyframe
    * `:interpolation_mode` - How to interpolate to the next keyframe (default: :linear)
  """
  @spec new(keyword()) :: {:ok, t()} | {:error, term()}
  def new(opts) do
    with {:ok, time} <- validate_time(opts[:time]),
         {:ok, properties} <- validate_properties(opts[:properties]),
         {:ok, easing} <- validate_easing(opts[:easing]),
         {:ok, interpolation_mode} <- validate_interpolation_mode(opts[:interpolation_mode] || :linear) do
      {:ok, %__MODULE__{
        time: time,
        properties: properties,
        easing: easing,
        interpolation_mode: interpolation_mode
      }}
    end
  end
  
  @doc """
  Creates a new keyframe, raising on error.
  """
  @spec new!(keyword()) :: t()
  def new!(opts) do
    case new(opts) do
      {:ok, keyframe} -> keyframe
      {:error, reason} -> raise ArgumentError, "Invalid keyframe: #{inspect(reason)}"
    end
  end
  
  @doc """
  Interpolates between two keyframes at a given progress point.
  
  Returns a map of interpolated property values.
  """
  @spec interpolate(t(), t(), float(), AshSvg.Timeline.easing_function()) :: %{atom() => property_value()}
  def interpolate(from, to, progress, easing \\ :linear) do
    # Apply easing to progress
    eased_progress = apply_easing(progress, from.easing || easing)
    
    # Get all unique property keys
    all_keys = from.properties
               |> Map.keys()
               |> Kernel.++(Map.keys(to.properties))
               |> Enum.uniq()
    
    # Interpolate each property
    Enum.reduce(all_keys, %{}, fn key, acc ->
      from_value = Map.get(from.properties, key)
      to_value = Map.get(to.properties, key)
      
      interpolated_value = case from.interpolation_mode do
        :discrete ->
          if eased_progress < 0.5, do: from_value, else: to_value
        :hold ->
          from_value
        _ ->
          interpolate_value(from_value, to_value, eased_progress)
      end
      
      Map.put(acc, key, interpolated_value)
    end)
  end
  
  # Private functions
  
  defp validate_time(nil), do: {:error, :time_required}
  defp validate_time(time) when is_float(time) and time >= 0.0 and time <= 1.0, do: {:ok, time}
  defp validate_time(time) when is_integer(time) and time >= 0, do: {:ok, time / 1.0}
  defp validate_time(_), do: {:error, :invalid_time}
  
  defp validate_properties(nil), do: {:error, :properties_required}
  defp validate_properties(props) when is_map(props), do: {:ok, props}
  defp validate_properties(_), do: {:error, :invalid_properties}
  
  defp validate_easing(nil), do: {:ok, nil}
  defp validate_easing(easing) do
    # Reuse Timeline's easing validation
    case AshSvg.Timeline.new(duration: 1000, easing: easing) do
      {:ok, _} -> {:ok, easing}
      _ -> {:error, :invalid_easing}
    end
  end
  
  defp validate_interpolation_mode(mode) when mode in [:linear, :discrete, :spline, :hold], do: {:ok, mode}
  defp validate_interpolation_mode(_), do: {:error, :invalid_interpolation_mode}
  
  defp apply_easing(progress, :linear), do: progress
  defp apply_easing(progress, :ease_in), do: progress * progress
  defp apply_easing(progress, :ease_out), do: progress * (2 - progress)
  defp apply_easing(progress, :ease_in_out) do
    if progress < 0.5 do
      2 * progress * progress
    else
      -1 + (4 - 2 * progress) * progress
    end
  end
  defp apply_easing(progress, {:cubic_bezier, x1, y1, x2, y2}) do
    # Simplified cubic bezier - in production would use proper solver
    # For now, approximate with linear
    _ = {x1, y1, x2, y2}
    progress
  end
  defp apply_easing(progress, {:custom, func}), do: func.(progress)
  
  defp interpolate_value(nil, to, _progress), do: to
  defp interpolate_value(from, nil, _progress), do: from
  defp interpolate_value(from, to, progress) when is_number(from) and is_number(to) do
    from + (to - from) * progress
  end
  defp interpolate_value(from, to, progress) when is_binary(from) and is_binary(to) do
    # For strings, use discrete interpolation
    if progress < 0.5, do: from, else: to
  end
  defp interpolate_value({fx, fy}, {tx, ty}, progress) do
    {interpolate_value(fx, tx, progress), interpolate_value(fy, ty, progress)}
  end
  defp interpolate_value({fx, fy, fz}, {tx, ty, tz}, progress) do
    {interpolate_value(fx, tx, progress), 
     interpolate_value(fy, ty, progress),
     interpolate_value(fz, tz, progress)}
  end
  defp interpolate_value({fx, fy, fz, fw}, {tx, ty, tz, tw}, progress) do
    {interpolate_value(fx, tx, progress), 
     interpolate_value(fy, ty, progress),
     interpolate_value(fz, tz, progress),
     interpolate_value(fw, tw, progress)}
  end
  defp interpolate_value(from, _to, _progress), do: from
end