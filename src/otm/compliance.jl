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

function diff_K(element::Element)
    aux::Float64 = element.area
    element.area = 1.0
    k = stiffness_global(element)
    element.area = aux
    
    return k
end

function diff_K(compliance::Compliance)
    # TODO: Optimize this
    # TODO: Implement virtual_dofs (degrees of freedom for constrained stiffness matrix)
    # TODO: Change stiffness methods to K0
    z = Z(compliance)

    g::Vector{SparseMatrixCSC{Float64}} = []

    for element in compliance.structure.elements
        loc_dofs_el = free_local_dofs(element)
        virt_dofs_el = virtual_dofs(element)

        z_el = z[virt_dofs_el,:]

        diff_k_el = diff_K(element)[loc_dofs_el, loc_dofs_el]

        push!(g, -z_el'*diff_k_el*z_el)
    end

    return g
end

function Z(compliance::Compliance)
    return stiffness_matrix(compliance.structure) \ H(compliance)
end
