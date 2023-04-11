include("node.jl")
include("material.jl")

"""
Defines an Element.

# Fields
- `id::Int64`: Element id.
- `area::Float64`: Element area.
- `nodes::Vector{Node}`: Element nodes.
- `material::Material`: Element material.

# Constructors
- `Element(id::Int64, area::Float64, nodes::Vector{Node}, material::Material)`: Creates a new element with the given id, area, nodes, and material.

# Errors
- `Id must be a positive integer`: The id must be a positive integer.
- `Element must have two nodes`: The element must have two nodes.
"""
mutable struct Element
    id::Int64
    area::Float64
    nodes::Vector{Node}
    material::Material

    function Element(id::Int64, area::Float64, nodes::Vector{Node}, material::Material)
        if id < 1
            throw(ArgumentError("Id must be a positive integer."))
        end

        if area < 0
            throw(ArgumentError("Area must be a non negative number."))
        end

        if length(nodes) != 2
            throw(ArgumentError("Element must have two nodes."))
        end

        if nodes[1] == nodes[2]
            throw(ArgumentError("Element nodes must be different."))
        end

        new(id, area, nodes, material)
    end
end

"""
Returns the element length.
"""
len(element::Element)::Float64 = distance(element.nodes...)

"""
Return the degrees of freedom of the element.
"""
dofs(element::Element)::Vector{Int64} = [dof for node in element.nodes for dof in dofs(node)]

"""
Returns the element force vector.
"""
forces(element::Element)::Vector{Float64} = [f for node in element.nodes for f in node.force]

"""
Returns the free degrees of freedom of the element.
"""
free_dofs(element::Element)::Vector{Int64} = [dof for node in element.nodes for dof in free_dofs(node)]

"""
Returns the angle (radians) between the element and the x-axis.
"""
function angle(element::Element)::Float64
    Δc = element.nodes[2].position - element.nodes[1].position
    atan(Δc[2], Δc[1])
end

"""
Returns the rotation matrix for the element.
"""
function rotation_matrix(element::Element)::Matrix{Float64}
    θ = angle(element)
    s = sin(θ)
    c = cos(θ)

    return [c s 0 0
            -s c 0 0
            0 0 c s
            0 0 -s c]
end

"""
Returns the element local stiffness matrix.
"""
function stiffness_local(element::Element)::Matrix{Float64}
    l = len(element)
    e = element.material.young
    a = element.area

    return (e * a / l) * [1 0 -1 0
                          0 0 0 0
                          -1 0 1 0
                          0 0 0 0]
end

"""
Returns the element global stiffness matrix.
"""
function stiffness_global(element::Element)::Matrix{Float64}
    r = rotation_matrix(element)
    kl = stiffness_local(element)

    return r' * kl * r
end
