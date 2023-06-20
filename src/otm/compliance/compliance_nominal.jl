include("base_compliance.jl")
include("../../../src/fea/structure.jl")

mutable struct ComplianceNominal <: Compliance
    base::BaseCompliance

    function ComplianceNominal(structure::Structure)
        new(BaseCompliance(structure))
    end
end

function diff_obj(compliance::ComplianceNominal)::Vector{Float64}
    disp = u(compliance.base.structure)
    els = compliance.base.structure.elements
    dx_obj = zeros(length(els))
    for (i, el) in enumerate(els)
        dofs_el = dofs(el, include_restricted=true)
        area_aux = el.area
        el.area = 1.0
        dx_obj[i] = -disp[dofs_el]' * K(el) * disp[dofs_el]
        el.area = area_aux
    end

    return dx_obj
end

function obj(compliance::ComplianceNominal)
    return forces(compliance.base.structure, include_restricted=true)' * u(compliance.base.structure)
end

function min_max_obj(compliance::ComplianceNominal)
    return [-1.0, -1.0]
end