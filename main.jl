include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 5
ny = 5
lx = 8.0
ly = 4.0

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0))
structure = build(builder)

restrict_nearest_node(structure, [0.0, 0.0], [true, true])
restrict_nearest_node(structure, [8.0, 0.0], [true, true])

load_nearest_node(structure, [lx/2, ly/2], [1.0, 1.0])

compliance = ComplianceSmoothPNorm(structure)

#vol = 0.05*lx*ly*1/450
vol = 1.0
optimizer = Optimizer(compliance, max_iters=1000, volume_max=vol)

optimize!(optimizer)

r = Plotter("output.json")
plot_optimized_structure(r, 10.0)
