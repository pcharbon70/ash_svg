defmodule AshSvg.MinimalDslTest do
  use ExUnit.Case, async: true
  
  test "DSL extension generates svg macro" do
    # Test if we can define a module with our DSL
    defmodule TestModule do
      use Spark.Dsl,
        default_extensions: [extensions: [AshSvg.Dsl]]
      
      # This should work if our DSL is properly set up
      svg do
        circle :test_circle do
          cx 50
          cy 50  
          r 20
        end
      end
    end
    
    # If we get here, the DSL compiled successfully
    assert Code.ensure_loaded?(TestModule)
  end
end