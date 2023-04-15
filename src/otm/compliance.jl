include("../fea/structure.jl")
using LinearAlgebra,
      SparseArrays


mutable struct Compliance
    structure::Structure
end


function H(compliance::Compliance)
    s = compliance.structure
    fl_dofs = free_loaded_dofs(s)
    
    h = spzeros(number_of_dofs(s), length(fl_dofs))
    
    c::Int64 = 1
    for i in fl_dofs
        h[i, c] = 1.0
        c += 1
    end

    return h
end

function diff_K(element::Element)
    aux::Float64 = element.area
    element.area = 1.0
    k = K(element)
    element.area = aux
    
    return k
end

function diff_K(compliance::Compliance)::Vector{SparseMatrixCSC{Float64}}
    # TODO: Optimize this
    # TODO: Implement virtual_dofs (degrees of freedom for constrained stiffness matrix)
    # TODO: Change stiffness methods to K0
    g::Vector{SparseMatrixCSC{Float64}} = []

    for element in compliance.structure.elements
        gi = spzeros(4, 4)
        dofs_el_loc = dofs(element, include_restricted=true, local_dofs=true)
        gi[dofs_el_loc, dofs_el_loc] = diff_K(element)[dofs_el_loc, dofs_el_loc]

        push!(g, gi)
    end

    return g
end

function Z(compliance::Compliance)
    return K(compliance.structure, include_restricted=true) \ H(compliance)
end

function diff_C(compliance::Compliance)
    g::Vector{Float64} = []
    z::Matrix{Float64} = Z(compliance)

    for element in compliance.structure.elements
        ze::Vector{Float64} = z[dofs(element, include_restricted=true), :]
        push!(g, -ze' * diff_K(element) * ze)
    end

    return g
end
