using LinearAlgebra

"""
Defines a point in 2D space.

# Fields
- `coords::Vector{Float64}`: The coordinates of the point.

# Constructors
- `Point(x::Float64, y::Float64)`: Creates a new point with the given coordinates.
- `Point()`: Creates a new point at the origin.
"""
mutable struct Point
    coords::Vector{Float64}

    function Point(x::Float64, y::Float64)
        new([x, y])
    end
    function Point()
        new([0.0, 0.0])
    end
end

"""
Returns the variation in coordinates between two points.
"""
Δcoords(p1::Point, p2::Point)::Vector{Float64} = p2.coords - p1.coords 

"""
Returns the distance between two points.
"""
function distance(p1::Point, p2::Point)::Float64
    return norm(Δcoords(p1, p2))
end
