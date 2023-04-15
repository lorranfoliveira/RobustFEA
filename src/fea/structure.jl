include("node.jl")
include("element.jl")
include("material.jl")

using NearestNeighbors, 
      LinearAlgebra,
      SparseArrays

"""
Defines a structure for use in the finite element method.

# Fields
- `nodes::Vector{Node}`: The nodes in the structure.
- `elements::Vector{Element}`: The elements in the structure.
- `tikhonov::Float64`: The tikhonov regularization parameter.

# Constructors
- `Structure(nodes::Vector{Node}, elements::Vector{Element}, tikhonov::Float64=1e-9)`: Creates a new structure with the given nodes, elements, and tikhonov regularization parameter.

# Errors
- `There must be at least one node.`
- `There must be at least one element.`
- `Tikhonov regularization must be a non negative number.`
"""
mutable struct Structure
    nodes::Vector{Node}
    elements::Vector{Element}
    tikhonov::Float64

    function Structure(nodes::Vector{Node}, elements::Vector{Element}; tikhonov::Float64=1e-9)
        if length(nodes) < 1
            throw(ArgumentError("There must be at least one node."))
        end

        if length(elements) < 1
            throw(ArgumentError("There must be at least one element."))
        end

        if tikhonov < 0
            throw(ArgumentError("Tikhonov regularization must be a positive number."))
        end
        
        new(nodes, elements, tikhonov)
    end
end

"""
Returns the closest node to the given position.
"""
function nearest_node_id(structure::Structure, position::Vector{Float64})::Int64
    m = Matrix{Float64}(undef, (2, length(structure.nodes)))

    for i in eachindex(nodes)
        m[1, i] = structure.nodes[i].position[1]
        m[2, i] = structure.nodes[i].position[2]
    end
    
    kd = KDTree(m)
    return knn(kd, position, 1)[1][1]
end

"""
Load the given force to the closest node to the given position.
"""
function load_nearest_node(structure::Structure, position::Vector{Float64}, forces::Vector{Float64})
    structure.nodes[nearest_node_id(structure, position)].forces = forces
end

"""
Set the given constraint to the closest node to the given position.
"""
function restrict_nearest_node(structure::Structure, position::Vector{Float64}, constraint::Vector{Bool})
    structure.nodes[nearest_node_id(structure, position)].constraint = constraint
end

"""
Returns the number of degrees of freedom for the given structure.
"""
number_of_dofs(structure::Structure)::Int64 = 2 * length(structure.nodes)

"""
Returns the free degrees of freedom for the given structure.
"""

constraint(structure::Structure) = [c for node in structure.nodes for c in node.constraint]

function restricted_dofs(structure::Structure; local_dofs::Bool=false)::Vector{Int64}
    return dofs(structure; include_restricted=true, local_dofs=local_dofs)[constraint(structure) .== true]
end

function dofs(structure::Structure; include_restricted::Bool=false, local_dofs::Bool=false)::Vector{Int64}
    r::Vector{Int64} = []

    if local_dofs
        r = Vector(1:number_of_dofs(structure))
    else
        r = [dof for node in structure.nodes for dof in dofs(node, include_restricted=true)]
    end

    return include_restricted ? r : r[constraint(structure) .== false]
end

function loaded_dofs(structure::Structure)
    
end

function free_loaded_dofs(structure::Structure; local_dofs=false)::Vector{Int64}
    return [dof for node in structure.nodes for dof in free_loaded_dofs(node, local_dofs=local_dofs)]
end

"""
Returns the volume of the given structure.
"""
volume(structure::Structure)::Float64 = sum([volume(element) for element in structure.elements])

"""
Returns the mass matrix for the given structure.
"""
function forces(structure::Structure; include_restricted::Bool=false, exclude_zeros::Bool=false)::Vector{Float64} 
    return [force for node in structure.nodes for force in forces(node, include_restricted=include_restricted, exclude_zeros=exclude_zeros)]
end

"""
Returns the stiffness matrix for the given structure.

TODO: This is a naive implementation. It should be improved.
"""
function K(structure::Structure; include_restricted=false)::Matrix{Float64}
    n::Int64 = number_of_dofs(structure)
    k::SparseMatrixCSC{Float64} = spzeros(n, n)

    for element in structure.elements
        dofs_el::Vector{Int64} = dofs(element, include_restricted=true)
        k[dofs_el, dofs_el] += K(element)
    end

    if !include_restricted
        f_dof = dofs(structure)
        k = k[f_dof, f_dof]
    end
    

    dropzeros!(k)

    dg = nonzeros(diag(k)) 
    λ = structure.tikhonov * (sum(dg) / length(dg))
    k += λ * I
    
    return k
end

"""
Returns the displacements for the given structure.
"""
u(structure::Structure) = K(structure) \ forces(structure)
