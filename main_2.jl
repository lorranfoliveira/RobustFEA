include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 5
ny = 5
lx = 6.0
ly = 6.0

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0), connectivity_ratio=Inf)
structure = build(builder)

restrict_nearest_node(structure, [0.0, 0.0], [true, true])
restrict_nearest_node(structure, [lx, 0.0], [true, true])

load_nearest_node(structure, [lx/(nx - 1), 0.0], [1.0, 1.0])
load_nearest_node(structure, [3*lx/(nx-1), 0.0], [1.0, 1.0])


#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure, p=20.0)

vol = 1.0
optimizer = Optimizer(compliance, max_iters=20000, volume_max=vol, filter_tol=Inf)

optimize!(optimizer)

r = Plotter("output.json")
plot_structure(r, "output_structure", 20.0)
