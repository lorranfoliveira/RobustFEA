include("../fea/structure.jl")
using LinearAlgebra,
      SparseArrays


mutable struct Compliance
    structure::Structure
end


function H(compliance::Compliance)
    s = compliance.structure
    # Free forces with zeros
    all_forces = free_forces(s)
    # Degrees of freedom of nonzero free forces
    dof_nonzero_forces = free_loaded_dofs(s)
    
    h = spzeros(length(all_forces), length(dof_nonzero_forces))

    c::Int64 = 1
    for i in eachindex(all_forces)
        if all_forces[i] != 0.0
            h[i, c] = 1.0
            c += 1
        end
    end

    return h
end

function diff_K(compliance::Compliance)
    # TODO: Optimize this
    # TODO: Implement virtual_dofs (degrees of freedom for constrained stiffness matrix)
    # TODO: Change stiffness methods to K
    n_dofs::Int64 = number_of_dofs(compliance.structure)
    g::Vector{SparseMatrixCSC{Float64}} = []

    for element in compliance.structure.elements
        gi::SparseMatrixCSC{Float64} = spzeros(n_dofs, n_dofs)
        dofs = dofs(element)

        tmp_area = element.area
        element.area = 1.0
        gi[dofs, dofs] = stiffness_global(element)
        element.area = tmp_area

        push!(g, gi)
    end

    return g
end

function Z(compliance::Compliance)
    return stiffness_matrix(compliance.structure) \ H(compliance)
end
