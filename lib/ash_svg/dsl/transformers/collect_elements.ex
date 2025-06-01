defmodule AshSvg.Dsl.Transformers.CollectElements do
  @moduledoc """
  Collects all SVG elements and persists them for easy access.
  
  This transformer gathers all SVG elements (including nested ones in groups)
  and stores them in the DSL state for use by other transformers and at runtime.
  """
  
  use Spark.Dsl.Transformer
  
  alias Spark.Dsl.Transformer
  
  @impl true
  def transform(dsl_state) do
    elements = dsl_state
              |> Transformer.get_entities([:svg])
              |> collect_all_elements()
    
    # Store elements by name for easy lookup
    elements_map = elements
                  |> Enum.map(fn element -> {element.name, element} end)
                  |> Map.new()
    
    dsl_state = Transformer.persist(dsl_state, :elements, elements)
    dsl_state = Transformer.persist(dsl_state, :elements_map, elements_map)
    
    {:ok, dsl_state}
  end
  
  defp collect_all_elements(entities) do
    Enum.flat_map(entities, fn entity ->
      case entity do
        %{elements: nested} when is_list(nested) ->
          # This is a group with nested elements
          [entity | collect_all_elements(nested)]
        _ ->
          # Regular element
          [entity]
      end
    end)
  end
  
  # Control execution order - run before BuildTimelines
  @impl true
  def after?(_), do: false
  
  @impl true
  def before?(AshSvg.Dsl.Transformers.BuildTimelines), do: true
  def before?(_), do: false
end