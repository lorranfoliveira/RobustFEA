include("../fea/structure.jl")
using LinearAlgebra,
      SparseArrays


"""
Compliance object.

Attributes
----------
structure::Structure
    Structure object.
p::Float64
    p-norm parameter.
compliance_type::Int64
    1: Exact compliance.
    2: Smoothed compliance.
eig_vals
    Eigenvalues of the C matrix.
eig_vecs
    Eigenvectors of the C matrix.
"""
mutable struct Compliance
    structure::Structure
    compliance_type::Int64
    p::Float64
    eig_vals
    eig_vecs

    function Compliance(structure::Structure, compliance_type::Int64=1, p::Float64=5.0)
        if compliance_type ∉ [1, 2]
            error("Invalid compliance type.")
        end

        new(structure, compliance_type, p, [], [])
    end
end


function calculate_C_eigenvals_and_eigenvecs(compliance::Compliance)
    c::Matrix{Float64} = C(compliance)
    compliance.eig_vals, compliance.eig_vecs = eigen(c)
end


"""
Derivative of the eigenvalues of the C matrix with respect to the design variables.
"""
function diff_eigenvals(compliance::Compliance)
    num_eigvals::Int64 = length(compliance.eig_vals)
    num_design_vars::Int64 = length(compliance.structure.elements)
    dC::Vector{Matrix{Float64}} = diff_C(compliance)
    
    g::Matrix{Float64} = zeros(num_eigvals, num_design_vars)

    for i=1:num_eigvals
        vecs::Vector{Float64} = compliance.eig_vecs[:, i]

        for j=1:num_design_vars
            g[i, j] = vecs' * dC[j] * vecs
        end
    end

    return g
end


"""
Exact compliance.
"""
function obj_exact(compliance::Compliance)::Float64
    return maximum(compliance.eig_vals)
end

"""
Smoothed compliance.
"""
function obj_smooth(compliance::Compliance)::Float64
    return norm(compliance.eig_vals, compliance.p)
end

# TODO: function obj_smooth_mu()

"""
Compliance.
"""
function obj(compliance::Compliance)::Float64
    if compliance.compliance_type == 1
        return obj_exact(compliance)
    elseif compliance.compliance_type == 2
        return obj_smooth(compliance)
    end
end

"""
Derivative of the exact compliance with respect to the design variables.
"""
function diff_obj_exact(compliance::Compliance)
    return diff_eigenvals(compliance)[end, :]
end

"""
Derivative of the smoothed compliance with respect to the design variables.
"""
function diff_obj_smooth(compliance::Compliance)
    calculate_C_eigenvals_and_eigenvecs(compliance)
    df_pnorm::Vector{Float64} = (compliance.eig_vals .^ (compliance.p - 1)) / (norm(compliance.eig_vals, compliance.p) ^ (compliance.p - 1))

    return df_pnorm' * diff_eigenvals(compliance)
end

"""
Derivative of the compliance with respect to the design variables.
"""
function diff_obj(compliance::Compliance)
    if compliance.compliance_type == 1
        return diff_obj_exact(compliance)
    elseif compliance.compliance_type == 2
        return diff_obj_smooth(compliance)
    end
end

"""
Matrix that maps the complete forces vector to the loaded forces vector.
"""
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

"""
Derivative of stiffness matrix of element with respect to the design variables.
"""
function diff_K(element::Element)::SparseMatrixCSC{Float64}
    aux::Float64 = element.area
    element.area = 1.0
    k::SparseMatrixCSC{Float64} = spzeros(4, 4)
    
    free_dofs::Vector{Int64} = dofs(element, include_restricted=false, local_dofs=true)
    k[free_dofs, free_dofs] = K(element)[free_dofs, free_dofs]
    element.area = aux
    
    return k
end

"""
Derivative of the stiffness matrix of the structure with respect to the design variables.
"""
diff_K(compliance::Compliance)::Vector{SparseMatrixCSC{Float64}} = [diff_K(element) for element in compliance.structure.elements]

"""
Auxiliar matrix Z.
"""
function Z(compliance::Compliance)
    return K(compliance.structure) \ H(compliance)
end

"""
Matrix where the eigenvalues are extracted from.
"""
function C(compliance::Compliance)::Matrix{Float64}
    z::Matrix{Float64} = Z(compliance)
    return z' * K(compliance.structure) * z
end 

"""
Derivative of C matrix.
"""
function diff_C(compliance::Compliance)
    g::Vector{Matrix{Float64}} = []
    z::Matrix{Float64} = Z(compliance)

    for element in compliance.structure.elements
        ze::Matrix{Float64} = z[dofs(element, include_restricted=true), :]
        push!(g, -ze' * diff_K(element) * ze)
    end

    return g
end
