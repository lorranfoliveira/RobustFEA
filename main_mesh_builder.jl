include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

lx = 2.0
ly = 1.0
nx = 3
ny = 2

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0), connectivity_ratio=Inf)
structure = build(builder)

restrict_nearest_node(structure, [0.0, 0.0], [true, true])
restrict_nearest_node(structure, [0.0, 1.0], [true, true])
load_nearest_node(structure, [2.0, 0.0], [1.0, 1.0])

#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure, p=20.0)
#compliance = ComplianceSmoothMu(structure, β=0.0)

vol = 1.0
optimizer = Optimizer(compliance, max_iters=10000, volume_max=vol, filter_tol=0.0, γ=0.0)

optimize!(optimizer)

r = Plotter(optimizer.output.filename)
plot_structure(r, "output_structure", 20.0)
#plot_compliance(r)
