include("../geometry/geometry.jl")
include("constraint.jl")

"""
Defines a node in 2D space.

# Fields
- `id::Int64`: The id of the node.
- `position::Point`: The position of the node.
- `force::Force`: The force applied to the node.
- `constraint::Constraint`: The constraint applied to the node.

# Constructors
- `Node(id::Int64, position::Point, force::Force, constraint::Constraint)`: Creates a new node with the given id, position, force and constraint.
"""
mutable struct Node
    id::Int64
    position::Point
    force::Force
    constraint::Constraint

    function Node(id::Int64, position::Point, force::Force, constraint::Constraint)
        new(id, position, force, constraint)
    end
end

"""
Returns the distance between two nodes.
"""
distance(node1::Node, node2::Node)::Float64 = distance(node1.position, node2.position)

"""
Returns the variation in coordinates between two nodes.
"""
dofs(node::Node)::Vector{Int64} = [2 * node.id - 1, 2 * node.id]

"""
Returns the variation in coordinates between two nodes.
"""
free_dofs(node::Node)::Vector{Int64} = [d for (d, c) in zip(dofs(node), node.constraint.dofs) if c]
