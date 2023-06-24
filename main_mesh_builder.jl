include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

lx = 2.0
ly = 1.0
nx = 7
ny = 7

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0), connectivity_ratio=Inf)
structure = build(builder)

restrict_nearest_nodes_inline_y(structure, ly, ny, 0.0, [true, true])
load_nearest_node(structure, [2.0, 0.0], [1.0, 1.0])

#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure, p=15.0)
#compliance = ComplianceSmoothMu(structure, β=0.0)

vol = 1.0
optimizer = Optimizer(compliance, max_iters=10000, volume_max=vol, filter_tol=0.0, γ=0.0)
#optimizer.layout_constraint = [5, 13]'
#optimizer.layout_constraint = [6, 8]'

x_ref = [2/3, 1.0, 4/3, 5/3]
t = []

for el in structure.elements
    node1 = el.nodes[1].position
    node2 = el.nodes[2].position

    for p in x_ref
        if isapprox(node1[1], p) && isapprox(node2[1], p)
            push!(t, el.id)
        end
    end
end

#optimizer.layout_constraint = t'

optimize!(optimizer)

println("areas: $([structure.elements[5].area, structure.elements[13].area])")

r = Plotter(optimizer.output.filename)
plot_structure(r, "output_structure", 20.0)
#plot_compliance(r)
