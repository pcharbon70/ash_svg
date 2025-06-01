defmodule AshSvg.Dsl.Verifiers.ValidateAnimationTargets do
  @moduledoc """
  Verifies that all animation targets reference existing SVG elements.
  
  This verifier ensures that animations with a target field reference
  an SVG element that has been defined in the same module.
  """
  
  use Spark.Dsl.Verifier
  
  alias Spark.Dsl.Verifier
  
  @impl true
  def verify(dsl_state) do
    elements = get_element_names(dsl_state)
    animations = get_animations(dsl_state)
    
    invalid_targets = animations
                     |> Enum.filter(fn animation -> 
                       animation.target && animation.target not in elements
                     end)
                     |> Enum.map(fn animation -> 
                       {animation.name, animation.target}
                     end)
    
    if Enum.empty?(invalid_targets) do
      :ok
    else
      error_message = invalid_targets
                     |> Enum.map(fn {anim_name, target} ->
                       "Animation #{inspect(anim_name)} targets non-existent element #{inspect(target)}"
                     end)
                     |> Enum.join("\n")
      
      {:error,
       Spark.Error.DslError.exception(
         message: "Invalid animation targets:\n#{error_message}",
         path: [:svg, :animations],
         module: Verifier.get_persisted(dsl_state, :module)
       )}
    end
  end
  
  defp get_element_names(dsl_state) do
    dsl_state
    |> Verifier.get_entities([:svg])
    |> Enum.map(& &1.name)
    |> get_nested_element_names(dsl_state)
  end
  
  defp get_nested_element_names(names, dsl_state) do
    # Also get names from nested groups
    groups = dsl_state
            |> Verifier.get_entities([:svg])
            |> Enum.filter(fn entity -> 
              entity.__struct__ == AshSvg.Dsl.Group
            end)
    
    nested_names = groups
                  |> Enum.flat_map(fn group ->
                    (group.elements || [])
                    |> Enum.map(& &1.name)
                  end)
    
    names ++ nested_names
  end
  
  defp get_animations(dsl_state) do
    dsl_state
    |> Verifier.get_entities([:svg, :animations])
  end
end