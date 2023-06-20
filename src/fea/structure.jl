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

    function Structure(nodes::Vector{Node}, elements::Vector{Element}; tikhonov::Float64=1e-12)
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

    for i in eachindex(structure.nodes)
        m[:, i] = structure.nodes[i].position
    end
    
    kd = KDTree(m)
    return knn(kd, position, 1)[1][1]
end

"""
Load the given force to the closest node to the given position.
"""
function load_nearest_node(structure::Structure, position::Vector{Float64}, force::Vector{Float64})
    structure.nodes[nearest_node_id(structure, position)].force = force
end

function load_nearest_nodes_inline_x(structure::Structure, lx::Float64, nx::Int64, y::Float64, force::Vector{Float64})
    for i=1:nx
        load_nearest_node(structure, [(i - 1)*(lx/(nx - 1)), y], force)
    end
end

function load_nearest_nodes_inline_y(structure::Structure, ly::Float64, ny::Int64, x::Float64, force::Vector{Float64})
    for i=1:ny
        load_nearest_node(structure, [x, (i - 1)*(ly/(ny - 1))], force)
    end
end

"""
Set the given constraint to the closest node to the given position.
"""
function restrict_nearest_node(structure::Structure, position::Vector{Float64}, constraint::Vector{Bool})
    structure.nodes[nearest_node_id(structure, position)].constraint = constraint
end

function restrict_nearest_nodes_inline_x(structure::Structure, lx::Float64, nx::Int64, y::Float64, constraint::Vector{Bool})
    for i=1:nx
        restrict_nearest_node(structure, [(i - 1)*(lx/(nx - 1)), y], constraint)
    end
end

function restrict_nearest_nodes_inline_y(structure::Structure, ly::Float64, ny::Int64, x::Float64, constraint::Vector{Bool})
    for i=1:ny
        restrict_nearest_node(structure, [x, (i - 1)*(ly/(ny - 1))], constraint)
    end
end

"""
Returns the number of degrees of freedom for the given structure.
"""
number_of_dofs(structure::Structure)::Int64 = 2 * length(structure.nodes)

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

function λ(k_structure::SparseMatrixCSC{Float64})::UniformScaling{Float64}
    dg = nonzeros(diag(k_structure)) 
    return structure.tikhonov * (sum(dg) / length(dg)) * I
end

"""
Returns the stiffness matrix for the given structure.

TODO: This is a naive implementation. It should be improved.
"""
function K(structure::Structure; use_tikhonov::Bool=true)::SparseMatrixCSC{Float64}
    n = length(structure.elements) * 4^2
    rows = ones(Int64, n)
    cols = ones(Int64, n)
    terms = zeros(n)
    c = 1

    for element in structure.elements
        dofs_el::Vector{Int64} = dofs(element, include_restricted=true)
        ke = K(element)
        for i=eachindex(dofs_el)
            for j=eachindex(dofs_el)
                rows[c] = dofs_el[i]
                cols[c] = dofs_el[j]
                terms[c] = ke[i, j]
                c += 1
            end
        end
    end

    k = sparse(rows, cols, terms)
    dropzeros!(k)

    cons::Vector{Bool} = constraint(structure)
    k[cons, :] .= 0.0
    k[:, cons] .= 0.0

    if use_tikhonov
        k += λ(k)
    end

    dropzeros!(k)
    
    df = dofs(structure)
    return k[df, df]
end

"""
Returns the displacements for the given structure.
"""
function u(structure::Structure)
    ut = zeros(number_of_dofs(structure))
    ut[dofs(structure)] = K(structure) \ forces(structure)
    return ut
end
