defmodule AshSvg.Info do
  @moduledoc """
  Introspection functions for AshSvg SVGs and animations.
  
  Provides functions to access SVG element definitions, animation definitions,
  and timelines from modules that use the AshSvg DSL.
  """
  
  use Spark.InfoGenerator,
    extension: AshSvg.Dsl,
    sections: [:svg]
  
  @doc """
  Gets all SVG elements defined in a module.
  
  Returns a list of element structs, including nested elements in groups.
  """
  def elements(module) do
    Spark.Dsl.Extension.get_persisted(module, :elements, [])
  end
  
  @doc """
  Gets a specific element by name.
  """
  def element(module, name) do
    module
    |> elements()
    |> Enum.find(fn element -> element.name == name end)
  end
  
  @doc """
  Gets all animations defined in a module.
  
  Returns the raw animation entities from the DSL.
  """
  def animations(module) do
    Spark.Dsl.Extension.get_entities(module, [:svg, :animations]) || []
  end
  
  @doc """
  Gets a specific animation entity by name.
  """
  def animation(module, name) do
    module
    |> animations()
    |> Enum.find(fn animation -> animation.name == name end)
  end
  
  @doc """
  Gets all built timelines from a module.
  
  Returns a keyword list of animation names to Timeline structs.
  """
  def timelines(module) do
    Spark.Dsl.Extension.get_persisted(module, :timelines, [])
  end
  
  @doc """
  Gets a specific timeline by animation name.
  """
  def timeline(module, name) do
    module
    |> timelines()
    |> Keyword.get(name)
  end
  
  @doc """
  Lists all animation names defined in a module.
  """
  def animation_names(module) do
    module
    |> animations()
    |> Enum.map(& &1.name)
  end
  
  @doc """
  Lists all element names defined in a module.
  """
  def element_names(module) do
    module
    |> elements()
    |> Enum.map(& &1.name)
  end
  
  @doc """
  Gets all animations that target a specific element.
  """
  def animations_for_element(module, element_name) do
    module
    |> animations()
    |> Enum.filter(fn animation -> animation.target == element_name end)
  end
  
  @doc """
  Gets all timelines that target a specific element.
  """
  def timelines_for_element(module, element_name) do
    module
    |> timelines()
    |> Enum.filter(fn {_name, timeline} ->
      timeline.metadata[:target] == element_name
    end)
  end
  
  @doc """
  Checks if an animation targets an existing element.
  """
  def valid_target?(module, animation_name) do
    case animation(module, animation_name) do
      nil -> false
      animation ->
        case animation.target do
          nil -> true  # No target is valid
          target ->
            element_names = element_names(module)
            target in element_names
        end
    end
  end
end