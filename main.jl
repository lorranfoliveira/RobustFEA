include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 3
ny = 2
lx = 2.0
ly = 1.0

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0), connectivity_ratio=0.0)
structure = build(builder)

restrict_nearest_node(structure, [0.0, 0.0], [true, true])
restrict_nearest_node(structure, [0.0, 1.0], [true, true])

load_nearest_node(structure, [lx, 0.0], [0.0, -1.0])

compliance = ComplianceNominal(structure)

vol = 1.0
#vol = 1.0
optimizer = Optimizer(compliance, max_iters=5000, volume_max=vol, filter_tol=1.0)

optimize!(optimizer)

r = Plotter("output.json")
plot_structure(r, "output_structure", 10.0)
