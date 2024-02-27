include("base_compliance.jl")
include("../../../src/fea/structure.jl")

mutable struct ComplianceThetaSmooth <: Compliance
    base::BaseCompliance
    theta_r::Float64
    β::Float64
    
    txx::Float64
    tyy::Float64
    txy::Float64

    diff_txx::Vector[Float64]
    diff_tyy::Vector[Float64]
    diff_txy::Vector[Float64]

    function ComplianceThetaSmooth(structure::Structure; theta_r::Float64=pi / 2, β::Float64=0.1)
        new(BaseCompliance(structure),
            β,
            theta_r,
            0.0,
            0.0,
            0.0,
            [],
            [],
            [])
    end
end

function forces_xy(structure::Structure)
    f = forces(structure; include_restricted=true)
    fx = [isodd(i) ? f[i] : 0.0 for i = eachindex(f)]
    fy = [!isodd(i) ? f[i] : 0.0 for i = eachindex(f)]
    return fx, fy
end

function update_txx_tyy_txy(compliance::ComplianceThetaSmooth)
    fx, fy = forces_xy(compliance.base.structure)

    k_str = K(compliance.base.structure)
    ux = k_str \ fx
    uy = k_str \ fy

    compliance.txx = fx' * ux
    compliance.tyy = fy' * uy
    compliance.txy = fx' * uy

    # Derivatives of txx, tyy, txy
    els = compliance.base.structure.elements
    nels = length(els)
    compliance.diff_txx = zeros(nels)
    compliance.diff_tyy = zeros(nels)
    compliance.diff_txy = zeros(nels)

    for (i, el) in enumerate(els)
        kel = K(el)

        dofs_el = dofs(el, include_restricted=true)
        area_aux = el.area
        el.area = 1.0

        compliance.diff_txx[i] = -ux[dofs_el]' * kel * ux[dofs_el]
        compliance.diff_tyy[i] = -uy[dofs_el]' * kel * uy[dofs_el]
        compliance.diff_txy[i] = -ux[dofs_el]' * kel * uy[dofs_el]

        el.area = area_aux
    end
end

function theta_max(txx::Float64, tyy::Float64, txy::Float64)::Float64
    return atan(2 * txy, txx - tyy) / 2
end

function thetas_lim(compliance::ComplianceThetaSmooth)
    tcr_1 = theta_max(compliance.txx, compliance.tyy, compliance.txy)
    tcr_2 = tcr_1 - pi / 2

    t1 = min(max(tcr_1, -compliance.theta_r), compliance.theta_r)
    t2 = min(max(tcr_2, -compliance.theta_r), compliance.theta_r)

    return t1, t2
end

function obj_theta(compliance::ComplianceThetaSmooth, theta::Float64)::Float64
    txx = compliance.txx
    tyy = compliance.tyy
    txy = compliance.txy
    return (txx + tyy) / 2 + (txx - tyy) / 2 * cos(2 * theta) + txy * sin(2 * theta)
end

function diff_obj_theta(compliance::ComplianceThetaSmooth, theta::Float64)::Float64
    diff_txx = compliance.diff_txx
    diff_tyy = compliance.diff_tyy
    diff_txy = compliance.diff_txy

    return 1 / 2 * (diff_txx - diff_tyy) * cos(2 * theta) + sin(2 * theta) * diff_txy + 1 / 2 * diff_txx + 1 / 2 * diff_tyy
end

function mu(compliance::ComplianceThetaSmooth)
    return (compliance.txx + compliance.tyy) / 2
end

function max_smooth(compliance::ComplianceThetaSmooth, f1::Float64, f2::Float64)
    return (f1 + f2 + sqrt((f1 - f2)^2 + mu(compliance)^2))
end

function c12(compliance::ComplianceThetaSmooth)
    theta_1, theta_2 = thetas_lim(compliance)
    c1 = obj_theta(compliance, theta_1)
    c2 = obj_theta(compliance, theta_2)

    return c1, c2
end

function diff_c12(compliance::ComplianceThetaSmooth)
    theta_1, theta_2 = thetas_lim(compliance)
    diff_c1 = diff_obj_theta(compliance, theta_1)
    diff_c2 = diff_obj_theta(compliance, theta_2)

    return diff_c1, diff_c2
end

function obj(compliance::ComplianceThetaSmooth)
    update_txx_tyy_txy(compliance)
    c1, c2 = c12(compliance)
    return max_smooth(compliance, c1, c2)
end

function diff_obj(compliance::ComplianceNominal)::Vector{Float64}
    update_txx_tyy_txy(compliance)
    c1, c2 = c12(compliance)
    diff_c1, diff_c2 = diff_c12(compliance)
    return (c1 - c2) * (diff_c1 - diff_c2) / sqrt(mu^2 + (c1 - c2)^2) + diff_c1 + diff_c2
end

function forces(compliance::ComplianceNominal)
    return forces(compliance.base.structure, include_restricted=true)
end
