using LinearAlgebra

"""
Defines a force in 2D space.

# Fields
- `forces::Vector{Float64}`: The forces in the x and y directions.

# Constructors
- `Force(fx::Float64, fy::Float64)`: Creates a new force with the given forces.
- `Force()`: Creates a new force with zero forces.
"""
mutable struct Force
    forces::Vector{Float64}

    function Force(fx::Float64, fy::Float64)
        new([fx, fy])
    end

    function Force()
        new([0.0, 0.0])
    end
end

"""
Returns the resultant of a force.
"""
function resultant(force::Force)
    return norm(force.forces)
end

"""
Returns the angle (radians) between the x-axis and the force.
"""
function angle(force::Force)
    return atan(force.forces[2], force.forces[1])
end
