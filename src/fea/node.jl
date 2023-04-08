include("../geometry/geometry.jl")

mutable struct Node
    id::Int64
    position::Point
    force::Force
    constraint::Constraint

    function Node(id::Int64, position::Point, force::Force, constraint::Constraint)
        new(id, position, force, constraint)
    end
end

distance(node1::Node, node2::Node) = distance(node1.position, node2.position)

dof(node::Node)::Vector{Float64} = [2 * id - 1, 2 * id]
