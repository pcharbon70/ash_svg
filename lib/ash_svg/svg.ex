defmodule AshSvg.Svg do
  @moduledoc """
  Base module for defining SVGs with animations using the AshSvg DSL.
  
  ## Example
  
      defmodule MyAnimatedSvg do
        use AshSvg.Svg
        
        svg do
          # Define SVG elements
          circle :my_circle do
            cx 100
            cy 100
            r 50
            fill "red"
          end
          
          rect :my_rect do
            x 10
            y 10
            width 100
            height 50
            fill "blue"
          end
          
          # Define animations for the elements
          animations do
            animation :circle_fade do
              target :my_circle
              duration 1000
              easing :ease_out
              
              keyframe 0.0 do
                set :opacity, 0
              end
              
              keyframe 1.0 do
                set :opacity, 1
              end
            end
            
            animation :rect_slide do
              target :my_rect
              duration 2000
              
              keyframe 0.0 do
                set :x, 10
              end
              
              keyframe 1.0 do
                set :x, 200
              end
            end
          end
        end
      end
  """
  
  defmacro __using__(_opts) do
    quote do
      use Spark.Dsl,
        default_extensions: [extensions: [AshSvg.Dsl]]
    end
  end
  
  @doc """
  Gets all animations defined in a module.
  
  Returns a keyword list of animation names to Timeline structs.
  """
  def animations(module) do
    Spark.Dsl.Extension.get_persisted(module, :timelines, [])
  end
  
  @doc """
  Gets a specific animation by name.
  """
  def get_animation(module, name) do
    module
    |> animations()
    |> Enum.find(fn {anim_name, _timeline} -> anim_name == name end)
    |> case do
      {^name, timeline} -> {:ok, timeline}
      nil -> {:error, :not_found}
    end
  end
  
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
  def get_element(module, name) do
    module
    |> elements()
    |> Enum.find(fn element -> element.name == name end)
    |> case do
      nil -> {:error, :not_found}
      element -> {:ok, element}
    end
  end
  
  @doc """
  Gets all animations for a specific element.
  """
  def animations_for_element(module, element_name) do
    module
    |> animations()
    |> Enum.filter(fn {_anim_name, timeline} ->
      # Get target from timeline metadata
      timeline.metadata[:target] == element_name
    end)
  end
  
  @doc """
  Validates that all animation targets exist as elements.
  """
  def validate_targets(module) do
    element_names = module
                   |> elements()
                   |> Enum.map(& &1.name)
                   |> MapSet.new()
    
    invalid_targets = module
                     |> animations()
                     |> Enum.filter(fn {_name, timeline} ->
                       target = timeline.metadata[:target]
                       target && !MapSet.member?(element_names, target)
                     end)
                     |> Enum.map(fn {name, timeline} ->
                       {name, timeline.metadata[:target]}
                     end)
    
    case invalid_targets do
      [] -> :ok
      targets -> {:error, {:invalid_targets, targets}}
    end
  end
end