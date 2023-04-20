include("base_compliance.jl")
include("../../../src/fea/structure.jl")

struct ComplianceSmoothMu <: Compliance
    base::BaseCompliance
    β::Float64

    function ComplianceSmoothMu(structure::Structure; β::Float64=0.1)
        new(BaseCompliance(structure), β)
    end
end

function μ(compliance::ComplianceSmoothMu)
    return compliance.β * sum(compliance.base.eig_vals) / length(compliance.base.eig_vals)
end


"""
Derivative of the smoothed compliance with respect to the design variables.
"""
function diff_obj(compliance::ComplianceSmoothMu)
    calculate_C_eigenvals_and_eigenvecs(compliance.base)
    c = compliance.base.eig_vals
    mu = μ(compliance)

    t = (2*sqrt(mu^2 + (c[1] - c[2])^2))

    df_mu = [1/2 + (c[1] - c[2]) / t, 1/2 + (c[2] - c[1]) / t]

    return (df_mu' * diff_eigenvals(compliance.base))'
end

function obj(compliance::ComplianceSmoothMu)
    c = compliance.base.eig_vals
    mu = μ(compliance)

    return (sqrt(mu^2 + (c[1] - c[2])^2) + c[1] + c[2])/2
end