include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 9
ny = 7
lx = 8.0
ly = 4.0
filename = "beam2.json"

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0))
structure = build(builder)

restrict_nearest_nodes_inline_y(structure, ly, ny, 0.0, [true, true])
load_nearest_nodes_inline_y(structure, ly, ny, lx, [1.0, 1.0])

#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure, p=Inf)

vol = 1.0
optimizer = Optimizer(compliance, max_iters=10000, volume_max=vol, filter_tol=0.1, filename=filename)

optimize!(optimizer)

r = Plotter(filename)
plot_structure(r, "output_structure", 20.0)
#plot_compliance(r)
