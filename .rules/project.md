# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AshSvg is a high-performance SVG animation system for Elixir built as an Ash Framework extension. It provides a declarative DSL (using Spark) for creating complex animations with Phoenix LiveView integration.

## Commands

### Development
```bash
# Install dependencies
mix deps.get

# Run tests
mix test

# Run a specific test file
mix test test/ash_svg_test.exs

# Run tests with coverage
mix test --cover

# Format code
mix format

# Compile with warnings as errors
mix compile --warnings-as-errors

# Start interactive shell
iex -S mix
```

### Dependencies
- Core: `ash ~> 3.0`, `spark ~> 2.0`
- Dev/Test: `sourceror ~> 1.8`, `igniter ~> 0.5`

## Architecture

### Core Design Principles
- **Timeline-first architecture**: Animations are modeled as immutable data structures that compose functionally
- **Server-side coordination**: Animation state is managed by GenServers with efficient delta broadcasting
- **Compile-time safety**: Spark DSL provides validation at compile time
- **Performance optimization**: Designed to handle 200+ simultaneous animations at 60fps

### Key Components

1. **Animation Engine** (Phase 1)
   - Timeline data model with keyframes and interpolation
   - Spark DSL for declarative animation definitions
   - Animation Coordinator GenServer for frame calculation
   - LiveView integration with JS hooks

2. **Ash Integration** (Phase 2)
   - AshSvg.Resource extension for animatable attributes
   - SVG element resources (Circle, Rectangle, Path, Group)
   - Domain-level scene management
   - Animation-resource binding system

3. **Performance Systems** (Phase 3)
   - Element pooling for DOM efficiency
   - Batched update system (16ms windows)
   - Adaptive quality based on FPS monitoring
   - Spatial indexing for game scenarios

4. **Advanced Features** (Phase 4)
   - Physics-based animations
   - Path morphing system
   - Animation preset library
   - Developer tools and visualizers

## Testing Strategy

Each implementation phase requires comprehensive tests before proceeding:
- Unit tests for each module (100% coverage target)
- Integration tests between components
- Performance benchmarks with realistic loads
- LiveView component tests
- Property-based tests for mathematical functions

Test organization:
```
test/
├── unit/           # Unit tests for each module
├── integration/    # Integration tests per phase
├── performance/    # Performance benchmarks
└── support/        # Test helpers and fixtures
```

## Implementation Status

Currently in initial planning phase. Implementation follows the detailed plan in `planning/detailed_implementation_plan.md` with 5 phases over 10 weeks.

## Important Files

- `planning/system_design.md` - Comprehensive system architecture and design decisions
- `planning/detailed_implementation_plan.md` - Task-by-task implementation breakdown
- `lib/ash_svg.ex` - Main module (currently placeholder)
- `mix.exs` - Project configuration and dependencies