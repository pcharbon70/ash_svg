defmodule AshSvg.TimelineTest do
  use ExUnit.Case, async: true
  
  alias AshSvg.{Timeline, Keyframe}
  
  describe "new/1" do
    test "creates a timeline with valid options" do
      assert {:ok, timeline} = Timeline.new(
        duration: 1000,
        keyframes: [],
        easing: :linear,
        loop_mode: :none,
        loop_count: 1,
        delay: 0
      )
      
      assert timeline.duration == 1000
      assert timeline.keyframes == []
      assert timeline.easing == :linear
      assert timeline.loop_mode == :none
      assert timeline.loop_count == 1
      assert timeline.delay == 0
    end
    
    test "requires duration" do
      assert {:error, :duration_required} = Timeline.new(keyframes: [])
    end
    
    test "validates duration is positive integer" do
      assert {:error, :invalid_duration} = Timeline.new(duration: 0)
      assert {:error, :invalid_duration} = Timeline.new(duration: -100)
      assert {:error, :invalid_duration} = Timeline.new(duration: 1.5)
      assert {:error, :invalid_duration} = Timeline.new(duration: "1000")
    end
    
    test "validates easing functions" do
      valid_easings = [:linear, :ease_in, :ease_out, :ease_in_out]
      
      for easing <- valid_easings do
        assert {:ok, timeline} = Timeline.new(duration: 1000, easing: easing)
        assert timeline.easing == easing
      end
      
      assert {:error, :invalid_easing} = Timeline.new(duration: 1000, easing: :invalid)
    end
    
    test "accepts cubic bezier easing" do
      assert {:ok, timeline} = Timeline.new(
        duration: 1000,
        easing: {:cubic_bezier, 0.25, 0.1, 0.25, 1.0}
      )
      
      assert timeline.easing == {:cubic_bezier, 0.25, 0.1, 0.25, 1.0}
    end
    
    test "accepts custom easing function" do
      custom_fn = fn t -> t * t end
      
      assert {:ok, timeline} = Timeline.new(
        duration: 1000,
        easing: {:custom, custom_fn}
      )
      
      assert {:custom, ^custom_fn} = timeline.easing
    end
    
    test "validates loop modes" do
      valid_modes = [:none, :restart, :reverse, :alternate]
      
      for mode <- valid_modes do
        assert {:ok, timeline} = Timeline.new(duration: 1000, loop_mode: mode)
        assert timeline.loop_mode == mode
      end
      
      assert {:error, :invalid_loop_mode} = Timeline.new(duration: 1000, loop_mode: :invalid)
    end
    
    test "validates loop count" do
      assert {:ok, timeline} = Timeline.new(duration: 1000, loop_count: 5)
      assert timeline.loop_count == 5
      
      assert {:ok, timeline} = Timeline.new(duration: 1000, loop_count: :infinite)
      assert timeline.loop_count == :infinite
      
      assert {:error, :invalid_loop_count} = Timeline.new(duration: 1000, loop_count: -1)
      assert {:error, :invalid_loop_count} = Timeline.new(duration: 1000, loop_count: 1.5)
    end
    
    test "validates delay" do
      assert {:ok, timeline} = Timeline.new(duration: 1000, delay: 500)
      assert timeline.delay == 500
      
      assert {:error, :invalid_delay} = Timeline.new(duration: 1000, delay: -100)
      assert {:error, :invalid_delay} = Timeline.new(duration: 1000, delay: 1.5)
    end
    
    test "accepts metadata" do
      metadata = %{name: "test", category: "UI"}
      assert {:ok, timeline} = Timeline.new(duration: 1000, metadata: metadata)
      assert timeline.metadata == metadata
    end
  end
  
  describe "new!/1" do
    test "creates timeline or raises" do
      timeline = Timeline.new!(duration: 1000)
      assert timeline.duration == 1000
      
      assert_raise ArgumentError, ~r/Invalid timeline/, fn ->
        Timeline.new!(duration: -1)
      end
    end
  end
  
  describe "timeline with keyframes" do
    test "accepts valid keyframes" do
      keyframes = [
        Keyframe.new!(time: 0.0, properties: %{x: 0}),
        Keyframe.new!(time: 0.5, properties: %{x: 50}),
        Keyframe.new!(time: 1.0, properties: %{x: 100})
      ]
      
      assert {:ok, timeline} = Timeline.new(duration: 1000, keyframes: keyframes)
      assert length(timeline.keyframes) == 3
    end
    
    test "validates keyframes is a list" do
      assert {:error, :invalid_keyframes} = Timeline.new(
        duration: 1000,
        keyframes: "not a list"
      )
    end
  end
  
  describe "default values" do
    test "uses sensible defaults" do
      {:ok, timeline} = Timeline.new(duration: 1000)
      
      assert timeline.keyframes == []
      assert timeline.easing == :linear
      assert timeline.loop_mode == :none
      assert timeline.loop_count == 1
      assert timeline.delay == 0
      assert timeline.metadata == %{}
    end
  end
end