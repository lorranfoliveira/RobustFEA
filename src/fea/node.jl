using LinearAlgebra

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
    position::Vector{Float64}
    force::Vector{Float64}
    constraint::Vector{Bool}

    function Node(id::Int64, position::Vector{Float64}, force::Vector{Float64}, constraint::Vector{Bool})
        if length(position) != 2
            throw(ArgumentError("Position must be a 2D vector."))
        end

        if length(force) != 2
            throw(ArgumentError("Force must be a 2D vector."))
        end

        if length(constraint) != 2
            throw(ArgumentError("Constraint must be a 2D vector."))
        end

        if id < 1
            throw(ArgumentError("Id must be a positive integer."))
        end

        new(id, position, force, constraint)
    end
end

"""
Returns the distance between two nodes.
"""
distance(node1::Node, node2::Node)::Float64 = norm(node2.position - node1.position)

"""
Returns the variation in coordinates between two nodes.
"""
dofs(node::Node)::Vector{Int64} = [2 * node.id - 1, 2 * node.id]

"""
Returns the variation in coordinates between two nodes.
"""
free_dofs(node::Node)::Vector{Int64} = [d for (d, c) in zip(dofs(node), node.constraint) if !c]
