using LinearAlgebra

"""
Defines a node for use in the finite element method.

# Fields
- `id::Int64`: The node id.
- `position::Vector{Float64}`: The position of the node.
- `force::Vector{Float64}`: The force applied to the node.
- `constraint::Vector{Bool}`: The constraint applied to the node.

# Constructors
- `Node(id::Int64, position::Vector{Float64}, force::Vector{Float64}, constraint::Vector{Bool})`: Creates a new node with the given id, position, force, and constraint.

# Errors
- `Position must be a 2D vector`: The position must be a 2D vector.
- `Force must be a 2D vector`: The force must be a 2D vector.
- `Constraint must be a 2D vector`: The constraint must be a 2D vector.
- `Id must be a positive integer`: The id must be a positive integer.
"""
mutable struct Node
    id::Int64
    position::Vector{Float64}
    forces::Vector{Float64}
    constraint::Vector{Bool}

    function Node(id::Int64, position::Vector{Float64}; forces::Vector{Float64}=[0.0, 0.0], constraint::Vector{Bool}=[false, false])
        if length(position) != 2
            throw(ArgumentError("Position must be a 2D vector."))
        end

        if length(forces) != 2
            throw(ArgumentError("Force must be a 2D vector."))
        end

        if length(constraint) != 2
            throw(ArgumentError("Constraint must be a 2D vector."))
        end

        if id < 1
            throw(ArgumentError("Id must be a positive integer."))
        end

        new(id, position, forces, constraint)
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

"""
Returns the forces of the free degrees of freedom.
"""
free_forces(node::Node)::Vector{Float64} = [force for (force, c) in zip(node.forces, node.constraint) if !c]
