defmodule AshSvg.Dsl.Entities do
  @moduledoc """
  Entity definitions for the AshSvg DSL.
  
  This module contains all the entity definitions as module attributes
  to avoid circular dependencies during compilation.
  """
  
  alias Spark.Dsl.Entity
  
  # Common attributes for all SVG elements
  @common_attributes [
    fill: [
      type: :string,
      doc: "The fill color of the element"
    ],
    stroke: [
      type: :string,
      doc: "The stroke color of the element"
    ],
    stroke_width: [
      type: :number,
      doc: "The width of the stroke"
    ],
    opacity: [
      type: :number,
      doc: "The opacity of the element (0.0 to 1.0)"
    ],
    transform: [
      type: :string,
      doc: "Transformation to apply to the element (e.g., 'rotate(45)')"
    ],
    class: [
      type: :string,
      doc: "CSS class to apply to the element"
    ],
    id: [
      type: :string,
      doc: "HTML id attribute for the element"
    ],
    style: [
      type: :string,
      doc: "Inline CSS styles"
    ]
  ]
  
  # Property setter for keyframes
  @property_setter %Entity{
    name: :set,
    target: AshSvg.Dsl.PropertySetter,
    describe: """
    Sets a property value at this keyframe.
    """,
    examples: [
      "set :opacity, 0.5",
      "set :position, {100, 200}",
      "set :color, {255, 0, 0, 1.0}"
    ],
    args: [:property, :value],
    schema: [
      property: [
        type: :atom,
        required: true,
        doc: "The property name to animate"
      ],
      value: [
        type: :any,
        required: true,
        doc: "The value for this property at this keyframe"
      ]
    ]
  }
  
  # Keyframe entity
  @keyframe %Entity{
    name: :keyframe,
    target: AshSvg.Dsl.Keyframe,
    describe: """
    Defines a keyframe at a specific point in the animation timeline.
    
    Keyframes specify property values at specific times during the animation.
    """,
    examples: [
      """
      keyframe 0.0 do
        set :opacity, 0
        set :x, -100
      end
      """,
      """
      keyframe 0.5 do
        set :opacity, 0.5
        set :x, 0
        interpolation :discrete
      end
      """
    ],
    args: [:time],
    schema: [
      time: [
        type: :float,
        required: true,
        doc: "Time position as a percentage (0.0 to 1.0) of the animation duration"
      ],
      interpolation: [
        type: {:in, [:linear, :discrete, :spline, :hold]},
        default: :linear,
        doc: "How to interpolate from this keyframe to the next"
      ],
      easing: [
        type: {:in, [:linear, :ease_in, :ease_out, :ease_in_out]},
        doc: "Optional easing override for this keyframe"
      ]
    ],
    entities: [
      properties: [@property_setter]
    ]
  }
  
  # Animation entity
  @animation %Entity{
    name: :animation,
    target: AshSvg.Dsl.Animation,
    describe: """
    Defines an animation with a timeline and configuration.
    
    Animations are the top-level construct that contains keyframes and timing information.
    """,
    examples: [
      """
      animation :fade_in do
        duration 1000
        easing :ease_out
        
        keyframe 0.0 do
          set :opacity, 0
        end
        
        keyframe 1.0 do
          set :opacity, 1
        end
      end
      """
    ],
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "A unique name for the animation"
      ],
      target: [
        type: :atom,
        doc: "The name of the SVG element to animate"
      ],
      duration: [
        type: :pos_integer,
        required: true,
        doc: "Duration of the animation in milliseconds"
      ],
      easing: [
        type: {:in, [:linear, :ease_in, :ease_out, :ease_in_out]},
        default: :linear,
        doc: "Easing function for the animation"
      ],
      loop_mode: [
        type: {:in, [:none, :restart, :reverse, :alternate]},
        default: :none,
        doc: "How the animation should loop"
      ],
      loop_count: [
        type: {:or, [:pos_integer, {:in, [:infinite]}]},
        default: 1,
        doc: "Number of times to loop the animation"
      ],
      delay: [
        type: :non_neg_integer,
        default: 0,
        doc: "Delay before starting the animation in milliseconds"
      ]
    ],
    entities: [
      keyframes: [@keyframe]
    ]
  }
  
  # SVG element entities
  @circle %Entity{
    name: :circle,
    target: AshSvg.Dsl.Circle,
    describe: """
    Defines a circle element in the SVG.
    
    A circle is defined by its center point (cx, cy) and radius (r).
    """,
    examples: [
      """
      circle :my_circle do
        cx 100
        cy 100
        r 50
        fill "red"
        stroke "black"
        stroke_width 2
      end
      """
    ],
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "A unique name for the circle element"
      ],
      cx: [
        type: :number,
        default: 0,
        doc: "The x-coordinate of the circle's center"
      ],
      cy: [
        type: :number,
        default: 0,
        doc: "The y-coordinate of the circle's center"
      ],
      r: [
        type: :number,
        required: true,
        doc: "The radius of the circle"
      ]
    ] ++ @common_attributes
  }
  
  @rect %Entity{
    name: :rect,
    target: AshSvg.Dsl.Rect,
    describe: """
    Defines a rectangle element in the SVG.
    
    A rectangle is defined by its position (x, y) and size (width, height).
    """,
    examples: [
      """
      rect :my_rect do
        x 10
        y 10
        width 100
        height 50
        fill "blue"
        rx 5
        ry 5
      end
      """
    ],
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "A unique name for the rectangle element"
      ],
      x: [
        type: :number,
        default: 0,
        doc: "The x-coordinate of the rectangle's top-left corner"
      ],
      y: [
        type: :number,
        default: 0,
        doc: "The y-coordinate of the rectangle's top-left corner"
      ],
      width: [
        type: :number,
        required: true,
        doc: "The width of the rectangle"
      ],
      height: [
        type: :number,
        required: true,
        doc: "The height of the rectangle"
      ],
      rx: [
        type: :number,
        doc: "The x-axis radius for rounded corners"
      ],
      ry: [
        type: :number,
        doc: "The y-axis radius for rounded corners"
      ]
    ] ++ @common_attributes
  }
  
  @path %Entity{
    name: :path,
    target: AshSvg.Dsl.Path,
    describe: """
    Defines a path element in the SVG.
    
    A path is defined by a series of commands and coordinates in the d attribute.
    """,
    examples: [
      """
      path :my_path do
        d "M 10 10 L 90 10 L 90 90 L 10 90 Z"
        fill "green"
        stroke "black"
      end
      """
    ],
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "A unique name for the path element"
      ],
      d: [
        type: :string,
        required: true,
        doc: "The path data defining the shape"
      ]
    ] ++ @common_attributes
  }
  
  # Note: Group entity defined without self-reference to avoid circular dependency
  @group %Entity{
    name: :group,
    target: AshSvg.Dsl.Group,
    describe: """
    Defines a group element in the SVG.
    
    A group is used to group other SVG elements together, allowing for
    collective transformations and styling. Groups cannot contain other groups
    to avoid circular dependencies.
    """,
    examples: [
      """
      group :my_group do
        transform "translate(50, 50)"
        
        circle :grouped_circle do
          cx 0
          cy 0
          r 25
          fill "orange"
        end
        
        rect :grouped_rect do
          x -25
          y -25
          width 50
          height 50
          fill "purple"
          opacity 0.5
        end
      end
      """
    ],
    args: [:name],
    schema: [
      name: [
        type: :atom,
        required: true,
        doc: "A unique name for the group element"
      ]
    ] ++ @common_attributes,
    entities: [
      elements: [@circle, @rect, @path]  # No @group to avoid circular ref
    ]
  }
  
  # Animations section
  @animations_section %Spark.Dsl.Section{
    name: :animations,
    describe: """
    A section for defining animations.
    
    This section contains all animation definitions for the SVG elements.
    """,
    examples: [
      """
      animations do
        animation :slide_in do
          duration 500
          
          keyframe 0.0 do
            set :x, -100
          end
          
          keyframe 1.0 do
            set :x, 0
          end
        end
      end
      """
    ],
    entities: [@animation]
  }
  
  # Public functions to access entities
  
  def circle, do: @circle
  def rect, do: @rect
  def path, do: @path
  def group, do: @group
  def animation, do: @animation
  def keyframe, do: @keyframe
  def property_setter, do: @property_setter
  def animations_section, do: @animations_section
  
  def svg_elements, do: [@circle, @rect, @path, @group]
end