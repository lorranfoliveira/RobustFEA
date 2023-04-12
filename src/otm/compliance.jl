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
