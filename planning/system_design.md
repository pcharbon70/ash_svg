# Designing an SVG Animation System for Elixir using Ash Framework and Spark DSL

Based on extensive research across JavaScript animation libraries, performance optimization techniques, DSL design patterns, and Elixir ecosystem capabilities, this report presents a comprehensive design for a high-performance SVG animation system as an Ash Framework extension.

## Architecture fundamentals: Timeline-first design with functional composition

The research reveals that the most successful animation libraries (GSAP, Anime.js, Motion One) share a **timeline-centric architecture** as their core organizational principle. For the Elixir implementation, this translates to modeling animations as immutable data structures that compose functionally:

```elixir
defmodule MyApp.Animations do
  use Ash.Domain.Extension, 
    extensions: [AshSvg.Animation]
  
  animation :hero_entrance do
    timeline do
      at 0.0 do
        element "#hero"
        opacity 0
        scale 0.5
        transform translate: {-100, 0}
      end
      
      at 0.5, element: "#hero", opacity: 0.8, scale: 1.2
      at 1.0, element: "#hero", opacity: 1.0, scale: 1.0
      
      parallel at: 0.3 do
        element "#shadow", opacity: [0, 0.5], duration: 700
        element "#glow", scale: [1, 1.5], opacity: [1, 0]
      end
    end
    
    duration 1000
    easing :spring, damping: 0.8
  end
end
```

This design leverages Spark's macro system to create a declarative DSL that compiles to efficient runtime structures, avoiding the performance overhead of runtime parsing while maintaining expressiveness.

## Performance architecture for hundreds of animated elements

The research identifies critical performance bottlenecks when animating hundreds of SVG elements. The proposed architecture addresses these through a **multi-tier optimization strategy**:

**1. Server-Side Animation Coordination**
```elixir
defmodule AshSvg.Animation.Coordinator do
  use GenServer
  
  # Maintains authoritative animation state
  defstruct [:animations, :frame, :subscribers, :element_pool]
  
  def handle_info(:tick, state) do
    # Calculate next frame state
    new_state = AnimationEngine.calculate_frame(state)
    
    # Generate minimal deltas
    deltas = DeltaCalculator.diff(state, new_state)
    
    # Broadcast batched updates
    Phoenix.PubSub.broadcast(
      MyApp.PubSub, 
      "animations:#{state.id}",
      {:animation_frame, deltas, state.frame}
    )
    
    {:noreply, new_state}
  end
end
```

**2. Client-Side Rendering Pipeline**
The system uses Phoenix LiveView JS Commands for simple animations while leveraging custom hooks for complex scenarios:

```elixir
defmodule AshSvg.LiveView.AnimationHelpers do
  import Phoenix.LiveView.JS
  
  def animate_simple(js \\ %JS{}, element, props) do
    js
    |> JS.transition(
      {"ease-out duration-300", 
       build_from_state(props), 
       build_to_state(props)},
      to: element
    )
  end
  
  def animate_complex(socket, animation_id) do
    push_event(socket, "svg-animation", %{
      animation_id: animation_id,
      coordinator_pid: self()
    })
  end
end
```

**3. Element Pooling and Reuse**
Based on performance research showing DOM manipulation as a primary bottleneck:

```elixir
defmodule AshSvg.ElementPool do
  use Agent
  
  def acquire(pool, element_type, count) do
    Agent.get_and_update(pool, fn state ->
      case Map.get(state.available, element_type, []) do
        available when length(available) >= count ->
          {taken, remaining} = Enum.split(available, count)
          {taken, put_in(state.available[element_type], remaining)}
        _ ->
          # Create new elements if pool exhausted
          new_elements = create_elements(element_type, count)
          {new_elements, state}
      end
    end)
  end
end
```

## DSL design: Declarative power with compile-time safety

The Spark-based DSL provides a declarative interface that compiles to efficient imperative operations:

```elixir
defmodule AshSvg.Animation.Dsl do
  @animation %Spark.Dsl.Entity{
    name: :animation,
    target: AshSvg.Animation,
    schema: [
      name: [type: :atom, required: true],
      duration: [type: :pos_integer, default: 1000],
      easing: [type: {:in, [:linear, :ease_in, :ease_out, :spring]}]
    ],
    entities: [timeline: []]
  }
  
  @timeline %Spark.Dsl.Entity{
    name: :timeline,
    target: AshSvg.Timeline,
    entities: [at: [], parallel: []],
    schema: [
      loop: [type: :boolean, default: false],
      direction: [type: {:in, [:normal, :reverse, :alternate]}]
    ]
  }
end
```

This provides compile-time validation while maintaining the flexibility needed for complex animations.

## Ash resource integration for SVG shapes

SVG elements are modeled as Ash resources, providing a consistent interface for manipulation:

```elixir
defmodule MyApp.Svg.Circle do
  use Ash.Resource,
    domain: MyApp.Svg,
    extensions: [AshSvg.Resource]
  
  attributes do
    uuid_primary_key :id
    attribute :cx, :float, allow_nil?: false
    attribute :cy, :float, allow_nil?: false
    attribute :r, :float, allow_nil?: false
    attribute :fill, :string
    attribute :stroke, :string
    attribute :opacity, :float, constraints: [min: 0.0, max: 1.0]
  end
  
  animations do
    animatable [:cx, :cy, :r, :opacity, :fill]
    
    preset :pulse do
      timeline do
        at 0.0, r: :current
        at 0.5, r: {:multiply, 1.2}
        at 1.0, r: :current
      end
      duration 1000
      loop true
    end
  end
end
```

## Scene animation at the domain level

Animations are declared at the Ash domain level, enabling complex scene orchestration:

```elixir
defmodule MyApp.Game do
  use Ash.Domain,
    extensions: [AshSvg.Domain]
  
  resources do
    resource MyApp.Svg.Circle
    resource MyApp.Svg.Rectangle
    resource MyApp.Svg.Path
  end
  
  scenes do
    scene :game_intro do
      # Define element creation
      create :sun, MyApp.Svg.Circle, 
        cx: 400, cy: 100, r: 50, fill: "yellow"
      
      create :ground, MyApp.Svg.Rectangle,
        x: 0, y: 400, width: 800, height: 200, fill: "green"
      
      # Define animations
      animation do
        sequence do
          animate :sun, :rise, duration: 2000
          parallel do
            animate :sun, :pulse, duration: 1000, repeat: 3
            animate :ground, :fade_in, duration: 500
          end
        end
      end
    end
  end
end
```

## Phoenix LiveView integration with JavaScript interoperability

The system provides seamless LiveView integration while abstracting JavaScript complexity:

```elixir
defmodule MyAppWeb.GameLive do
  use MyAppWeb, :live_view
  use AshSvg.LiveView
  
  def mount(_params, _session, socket) do
    {:ok, 
     socket
     |> assign_scene(:game_intro)
     |> start_animation(:entrance)}
  end
  
  def handle_event("user_click", %{"x" => x, "y" => y}, socket) do
    {:noreply,
     socket
     |> create_element(:explosion, MyApp.Svg.Burst, x: x, y: y)
     |> animate_element(:explosion, :expand_fade)}
  end
end
```

The corresponding LiveView template uses minimal markup:

```heex
<div id="game-container" phx-click="user_click">
  <.svg_scene scene={@scene} animations={@animations} />
</div>
```

## Performance optimization strategies

Based on the research findings, the system implements several key optimizations:

**1. Intelligent Batching**: All DOM updates are batched into 16ms windows (60fps) and applied using requestAnimationFrame.

**2. Transform-Only Animations**: The system preferentially uses CSS transforms which are hardware-accelerated:
```elixir
# Compiles to: transform: translate(100px, 50px) scale(1.5)
animate element: "#box", x: 100, y: 50, scale: 1.5
```

**3. Adaptive Quality**: The system monitors frame rates and automatically degrades quality for complex scenes:
```elixir
defmodule AshSvg.Performance.Monitor do
  def check_performance(metrics) do
    case metrics.fps do
      fps when fps < 30 -> :reduce_quality
      fps when fps < 50 -> :moderate_quality  
      _ -> :full_quality
    end
  end
end
```

**4. Spatial Indexing**: For games with collision detection, the system uses ETS-backed spatial indexing:
```elixir
defmodule AshSvg.SpatialIndex do
  def query_region(bounds) do
    :ets.select(:spatial_index, [
      {{'$1', '$2', '$3'}, 
       [{:andalso, 
         {:>=, '$2', bounds.min_x},
         {:'=<', '$2', bounds.max_x}}], 
       ['$1']}
    ])
  end
end
```

## Recommended implementation roadmap

**Phase 1: Core Animation Engine (Weeks 1-3)**
- Implement timeline-based animation model
- Create Spark DSL for animation declaration  
- Build server-side animation coordinator
- Develop basic LiveView integration

**Phase 2: Ash Integration (Weeks 4-5)**
- Create AshSvg.Resource extension
- Implement domain-level scene management
- Build resource-based animation system
- Add compile-time validation

**Phase 3: Performance Optimization (Weeks 6-7)**
- Implement element pooling
- Add batched update system
- Create adaptive quality system
- Build spatial indexing for games

**Phase 4: Advanced Features (Weeks 8-9)**
- Add physics-based animations
- Implement path morphing
- Create animation preset library
- Build debugging/visualization tools

This architecture leverages Elixir's strengths in concurrent processing and Phoenix's real-time capabilities while addressing SVG's performance limitations through intelligent optimization strategies. The result is a powerful, declarative animation system that maintains high performance even with hundreds of animated elements.
