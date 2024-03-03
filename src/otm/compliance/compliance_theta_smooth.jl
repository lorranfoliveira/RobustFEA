include("base_compliance.jl")
include("../../../src/fea/structure.jl")

mutable struct ComplianceThetaSmooth <: Compliance
    base::BaseCompliance
    theta_r::Float64
    β::Float64
    
    txx::Float64
    tyy::Float64
    txy::Float64

    diff_txx::Vector{Float64}
    diff_tyy::Vector{Float64}
    diff_txy::Vector{Float64}

    μ::Float64

    function ComplianceThetaSmooth(structure::Structure; theta_r::Float64=pi / 2, β::Float64=0.1)
        new(BaseCompliance(structure),
            theta_r,
            β,
            0.0,
            0.0,
            0.0,
            [],
            [],
            [],
            0.0)
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
    
    df = dofs(compliance.base.structure, include_restricted=false)
    fx = fx[df]
    fy = fy[df]

    k_str = K(compliance.base.structure)
    ux = k_str \ fx
    uy = k_str \ fy

    compliance.txx = fx' * ux
    compliance.tyy = fy' * uy
    compliance.txy =  fx' * uy

    if compliance.μ == 0.0
        compliance.μ = compliance.β * (compliance.txx + compliance.tyy) / 2
    end

    # Derivatives of txx, tyy, txy
    els = compliance.base.structure.elements
    num_els = length(els)
    num_nodes = length(compliance.base.structure.nodes)
    
    compliance.diff_txx = zeros(num_els)
    compliance.diff_tyy = zeros(num_els)
    compliance.diff_txy = zeros(num_els)

    ux_full = zeros(2*num_nodes)
    ux_full[df] = ux
    
    uy_full = zeros(2*num_nodes)
    uy_full[df] = uy

    for (i, el) in enumerate(els)
        dofs_el = dofs(el, include_restricted=true)
        area_aux = el.area
        kel = K(el)/el.area

        compliance.diff_txx[i] = -ux_full[dofs_el]' * kel * ux_full[dofs_el]
        compliance.diff_tyy[i] = -uy_full[dofs_el]' * kel * uy_full[dofs_el]
        compliance.diff_txy[i] = -ux_full[dofs_el]' * kel * uy_full[dofs_el]
    end
end

function thetas_lim(compliance::ComplianceThetaSmooth)
    txx = compliance.txx
    tyy = compliance.tyy
    txy = compliance.txy
    theta_r = compliance.theta_r

    theta_cr_max = atan(2 * txy, txx - tyy) / 2
    theta_cr_min = theta_cr_max + pi / 2

    if !(-pi / 2 <= theta_cr_min <= pi / 2)
        theta_cr_min = theta_cr_max - pi/2
    end

    if (theta_cr_max <= -theta_r && theta_cr_min <= -theta_r) || (theta_cr_max >= theta_r && theta_cr_min >= theta_r)
        theta_1 = -theta_r
        theta_2 = theta_r
    else
        if theta_cr_max < -theta_r
            theta_1 = -theta_r
        elseif theta_cr_max > theta_r
            theta_1 = theta_r
        else
            theta_1 = theta_cr_max
        end

        if theta_cr_min < -theta_r
            theta_2 = -theta_r
        elseif theta_cr_min > theta_r
            theta_2 = theta_r
        else
            theta_2 = theta_cr_min
        end
    end

    return theta_1, theta_2
end

function obj_theta(compliance::ComplianceThetaSmooth, theta::Float64)::Float64
    txx = compliance.txx
    tyy = compliance.tyy
    txy = compliance.txy
    return (txx + tyy) / 2 + (txx - tyy) / 2 * cos(2 * theta) + txy * sin(2 * theta)
end

function diff_obj_theta(compliance::ComplianceThetaSmooth, theta::Float64)::Vector{Float64}
    diff_txx = compliance.diff_txx
    diff_tyy = compliance.diff_tyy
    diff_txy = compliance.diff_txy

    return 1 / 2 * (diff_txx - diff_tyy) * cos(2 * theta) + sin(2 * theta) * diff_txy + 1 / 2 * diff_txx + 1 / 2 * diff_tyy
end

function max_smooth(compliance::ComplianceThetaSmooth, f1::Float64, f2::Float64)
    return (f1 + f2 + sqrt((f1 - f2)^2 + compliance.μ^2))/2
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
    θ1, θ2 = thetas_lim(compliance)
    println("θ1: $θ1, θ2: $θ2, txx: $(compliance.txx), tyy: $(compliance.tyy), txy: $(compliance.txy)")
    update_txx_tyy_txy(compliance)
    c1, c2 = c12(compliance)
    return max_smooth(compliance, c1, c2)
end

function theta_ef(compliance::ComplianceThetaSmooth)::Float64
    theta_1, theta_2 = thetas_lim(compliance)
    c1, c2 = c12(compliance)
    c = max_smooth(compliance, c1, c2)

    return abs(c - c1) < abs(c - c2) ? theta_1 : theta_2
end

function diff_obj(compliance::ComplianceThetaSmooth)::Vector{Float64}
    update_txx_tyy_txy(compliance)
    c1, c2 = c12(compliance)
    diff_c1, diff_c2 = diff_c12(compliance)

    txx = compliance.txx
    tyy = compliance.tyy
    txy = compliance.txy
    diff_txx = compliance.diff_txx
    diff_tyy = compliance.diff_tyy
    diff_txy = compliance.diff_txy

    return (c1 - c2) * (diff_c1 - diff_c2) / sqrt(compliance.μ^2 + (c1 - c2)^2) + diff_c1 + diff_c2
end

function forces(compliance::ComplianceThetaSmooth)
    t = theta_ef(compliance)
    fx, fy = forces_xy(compliance.base.structure)
    return fx * cos(t) + fy * sin(t)
end
