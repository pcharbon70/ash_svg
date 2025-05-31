defmodule AshSvg.Test.TimelineHelpers do
  @moduledoc """
  Helper functions for timeline-related tests.
  """
  
  alias AshSvg.{Timeline, Keyframe}
  
  @doc """
  Creates a simple timeline with two keyframes for testing.
  """
  def simple_timeline(opts \\ []) do
    duration = Keyword.get(opts, :duration, 1000)
    
    Timeline.new!(
      duration: duration,
      keyframes: [
        Keyframe.new!(time: 0.0, properties: %{opacity: 0, x: 0}),
        Keyframe.new!(time: 1.0, properties: %{opacity: 1, x: 100})
      ],
      easing: Keyword.get(opts, :easing, :linear)
    )
  end
  
  @doc """
  Creates a complex timeline with multiple keyframes.
  """
  def complex_timeline(opts \\ []) do
    Timeline.new!(
      duration: Keyword.get(opts, :duration, 2000),
      keyframes: [
        Keyframe.new!(time: 0.0, properties: %{x: 0, y: 0, scale: 1}),
        Keyframe.new!(time: 0.25, properties: %{x: 100, y: 50, scale: 1.5}),
        Keyframe.new!(time: 0.5, properties: %{x: 200, y: 100, scale: 1}),
        Keyframe.new!(time: 0.75, properties: %{x: 150, y: 75, scale: 0.8}),
        Keyframe.new!(time: 1.0, properties: %{x: 0, y: 0, scale: 1})
      ],
      easing: Keyword.get(opts, :easing, :ease_in_out),
      loop_mode: Keyword.get(opts, :loop_mode, :none)
    )
  end
  
  @doc """
  Creates a timeline with string properties for testing.
  """
  def string_timeline do
    Timeline.new!(
      duration: 1000,
      keyframes: [
        Keyframe.new!(time: 0.0, properties: %{text: "start", color: "red"}),
        Keyframe.new!(time: 0.5, properties: %{text: "middle", color: "green"}),
        Keyframe.new!(time: 1.0, properties: %{text: "end", color: "blue"})
      ]
    )
  end
  
  @doc """
  Creates a timeline with vector properties.
  """
  def vector_timeline do
    Timeline.new!(
      duration: 1000,
      keyframes: [
        Keyframe.new!(time: 0.0, properties: %{
          position2d: {0, 0},
          position3d: {0, 0, 0},
          color: {255, 0, 0, 1.0}
        }),
        Keyframe.new!(time: 1.0, properties: %{
          position2d: {100, 100},
          position3d: {50, 50, 50},
          color: {0, 255, 0, 1.0}
        })
      ]
    )
  end
  
  @doc """
  Asserts that two floats are approximately equal.
  """
  def assert_approx_equal(a, b, tolerance \\ 0.0001) do
    diff = abs(a - b)
    assert diff < tolerance, "Expected #{a} to be approximately #{b}, but difference was #{diff}"
  end
  
  @doc """
  Gets current timestamp in milliseconds.
  """
  def now_ms do
    System.monotonic_time(:millisecond)
  end
end