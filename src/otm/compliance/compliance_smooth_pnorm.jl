include("base_compliance.jl")
include("../../../src/fea/structure.jl")

mutable struct ComplianceSmoothPNorm <: ComplianceSmooth
    base::BaseCompliance
    p::Float64
    p_min::Float64
    p_max::Float64

    function ComplianceSmoothPNorm(structure::Structure; p::Float64=5.0, p_min::Float64=5.0, p_max::Float64=20.0)
        new(BaseCompliance(structure), p, p_min, p_max)
    end
end

"""
Derivative of the smoothed compliance with respect to the design variables.
"""
function diff_obj(compliance::ComplianceSmoothPNorm)
    calculate_C_eigenvals_and_eigenvecs(compliance.base)
    p = compliance.p
    eig_vals = compliance.base.eig_vals
    df_pnorm = (eig_vals .^ (p - 1)) / (norm(eig_vals, p) ^ (p - 1))

    return (df_pnorm' * diff_eigenvals(compliance.base))'
end

function obj(compliance::ComplianceSmoothPNorm; recalculate_eigenvals::Bool=false)
    if recalculate_eigenvals
        calculate_C_eigenvals_and_eigenvecs(compliance.base)
    end
    return norm(compliance.base.eig_vals, compliance.p)
end
