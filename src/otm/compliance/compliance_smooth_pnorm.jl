include("base_compliance.jl")
include("../../../src/fea/structure.jl")

mutable struct ComplianceSmoothPNorm <: ComplianceSmooth
    base::BaseCompliance
    p::Float64

    function ComplianceSmoothPNorm(structure::Structure; p::Float64=30.0)
        new(BaseCompliance(structure), p)
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
