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

constraint(element::Element) = vcat(element.nodes[1].constraint, element.nodes[2].constraint)

function free_loaded_dofs(element::Element; local_dofs::Bool=false)
    cond::Vector{Bool} = .!constraint(element) .&& forces(element, include_restricted=true) .!= 0.0
    return dofs(element, include_restricted=true, local_dofs=local_dofs)[cond]
end

"""
Return the degrees of freedom of the element.

# Arguments
- `include_restricted::Bool=false`: If true, returns the degrees of freedom of the element including those of constrained nodes.
- `local_dofs::Bool=false`: If true, returns the local degrees of freedom of the element.
"""
function dofs(element::Element; include_restricted::Bool=false, local_dofs::Bool=false)::Vector{Int64}
    r::Vector{Int64} = []

    if local_dofs
        r = Vector(1:4)
    else
        r = [dof for node in element.nodes for dof in dofs(node, include_restricted=true)]
    end

    return include_restricted ? r : r[constraint(element) .== false]
end


"""
Returns the element force vector including those of constrined degrees of freedom.

# Arguments
- `include_restricted::Bool=false`: If true, returns the force vector including those of constrained degrees of freedom.
- `exclude_zeros::Bool=false`: If true, returns the force vector excluding those of zero values.
"""
function forces(element::Element; include_restricted::Bool=false, exclude_zeros::Bool=false)::Vector{Float64}
    return [f for node in element.nodes for f in forces(node, include_restricted=include_restricted, exclude_zeros=exclude_zeros)]
end

"""
Returns the element volume.
"""
volume(element::Element)::Float64 = element.area * len(element)

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
function K_local(element::Element)::Matrix{Float64}
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
function K(element::Element)::Matrix{Float64}
    r = rotation_matrix(element)
    kl = K_local(element)

    return r' * kl * r
end
