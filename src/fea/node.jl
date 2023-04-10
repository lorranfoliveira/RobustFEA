include("../geometry/geometry.jl")
include("constraint.jl")

mutable struct Node
    id::Int64
    position::Point
    force::Force
    constraint::Constraint

    function Node(id::Int64, position::Point, force::Force, constraint::Constraint)
        new(id, position, force, constraint)
    end
end

distance(node1::Node, node2::Node)::Float64 = distance(node1.position, node2.position)

dofs(node::Node)::Vector{Float64} = [2 * node.id - 1, 2 * node.id]

free_dofs(node::Node)::Vector{Float64} = [d for (d, c) in zip(dofs(node), node.constraint.dofs) if c]
