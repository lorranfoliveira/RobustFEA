include("base_compliance.jl")
include("../../../src/fea/structure.jl")

mutable struct ComplianceSmoothPNorm <: ComplianceSmooth
    base::BaseCompliance
    p::Float64

    function ComplianceSmoothPNorm(structure::Structure; p::Float64=20.0, unique_loads_angle::Bool=true)
        new(BaseCompliance(structure, unique_loads_angle), p)
    end
end

"""
Derivative of the smoothed compliance with respect to the design variables.
"""
function diff_obj(compliance::ComplianceSmoothPNorm)
    calculate_C_eigenvals_and_eigenvecs(compliance.base)

    if compliance.p < Inf
        p = compliance.p
        eig_vals = compliance.base.eig_vals
        df_pnorm = (eig_vals .^ (p - 1)) / (norm(eig_vals, p) ^ (p - 1))

        return (df_pnorm' * diff_eigenvals(compliance.base))'
    else
        return diff_eigenvals(compliance.base)[end,:]
    end
end

function obj(compliance::ComplianceSmoothPNorm; recalculate_eigenvals::Bool=false)
    if recalculate_eigenvals
        calculate_C_eigenvals_and_eigenvecs(compliance.base)
    end
    return norm(compliance.base.eig_vals, compliance.p)
end

function min_max_obj(compliance::ComplianceSmoothPNorm; recalculate_eigenvals::Bool=false)
    if recalculate_eigenvals
        calculate_C_eigenvals_and_eigenvecs(compliance.base)
    end

    return compliance.base.eig_vals[[1, end]]
end
