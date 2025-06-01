# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

@include .rules/ash.md
@include .rules/spark.md
@include .rules/project.md

You must read the files listed as references above that use the @include syntax.

## Spark DSL Organization

When implementing Spark DSL extensions:
- Each `Spark.Dsl.Section` should be in its own module under a `sections` directory (e.g., `lib/ash_svg/dsl/sections/animations.ex`)
- Section modules should contain functions that return the section and all its entities:
  - `section/0` - returns the `%Spark.Dsl.Section{}` struct
  - Individual functions for each entity (e.g., `animation/0`, `keyframe/0`)
- The main DSL module should only use `Spark.Dsl.Extension` and reference sections via function calls:
  ```elixir
  use Spark.Dsl.Extension,
    sections: [AshSvg.Dsl.Sections.Animations.section()]
  ```
- This pattern keeps the DSL modular and makes sections reusable

## Spark DSL Validation

When implementing validation logic for Spark DSL usage:
- Always use `Spark.Dsl.Verifier` behavior instead of standalone validation modules
- Place verifiers in a `verifiers` subdirectory under the DSL module (e.g., `lib/ash_svg/dsl/verifiers/`)
- Use `Spark.Error.DslError` for error reporting with proper path and module context
- Access DSL entities through `Spark.Dsl.Verifier.get_entities/2` and related functions
- Validation that occurs at compile-time for DSL correctness should be a Verifier
- Runtime validation of data should remain as regular validation modules

