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

function update_smooth_parameter!(compliance::ComplianceSmoothPNorm)
    p_tmp = compliance.p
    base = compliance.base

    term = (base.obj_k - base.obj_km1) * (base.obj_km1 - base.obj_km2)
    if term < 0
        p_tmp = 0.9 * compliance.p
    elseif term > 0
        p_tmp = 1.1 * compliance.p
    end

    compliance.p = max(compliance.p_min, min(p_tmp, compliance.p_max))
end

function state_to_string(compliance::ComplianceSmoothPNorm)
    return "obj: $(compliance.base.obj_k)\t p: $(compliance.p)"
end