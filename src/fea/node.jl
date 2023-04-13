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
    force::Vector{Float64}
    constraint::Vector{Bool}

    function Node(id::Int64, position::Vector{Float64}; force::Vector{Float64}=[0.0, 0.0], constraint::Vector{Bool}=[false, false])
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
Returns the degrees of freedom.

# Keyword Arguments
- `include_restricted::Bool=false`: Whether to include the restricted degrees of freedom.
- `local_dofs::Bool=false`: Whether to return the local degrees of freedom (1:number_of_dofs).
"""
function dofs(node::Node; include_restricted::Bool=false, local_dofs::Bool=false)::Vector{Int64}
    r::Vector{Int64} = []

    if local_dofs
        r = Vector(1:2)
    else
        r = [2 * node.id - 1, 2 * node.id]
    end

    if include_restricted
        return r
    else
        return r[node.constraint .== false]
    end
end

"""
Returns true if the degree of freedom is loaded.
"""
function free_loaded_dofs(node::Node; local_dofs::Bool=false)::Vector{Int64}
    r::Vector{Int64} = dofs(node; include_restricted=true, local_dofs=local_dofs)
    cond::Vector{Bool} = @. node.constraint == false && node.force .!= 0.0
    return r[cond]
end

"""
Returns the forces of the degrees of freedom.
"""
function forces(node::Node; include_restricted::Bool=false, exclude_zeros::Bool=false)::Vector{Float64}
    f::Vector{Float64} = node.force[dofs(node; include_restricted=include_restricted, local_dofs=true)]
    
    if exclude_zeros
        return f[f .!= 0.0]
    else
        return f
    end
end
