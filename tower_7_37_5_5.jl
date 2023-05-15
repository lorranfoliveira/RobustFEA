include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 7
ny = 37
lx = 2.0
ly = 6.0
filename = "tower_7_37_5_5.json"

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1e5))
structure = build(builder)

restrict_nearest_nodes_inline_x(structure, lx, nx, 0.0, [true, true])

load_nearest_node(structure, [lx/2, ly], [5.0, 5.0])

#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure)

vol = lx*ly*0.5/450
optimizer = Optimizer(compliance, max_iters=20000, volume_max=vol, filter_tol=0.1, filename=filename)

optimize!(optimizer)

r = Plotter(filename)
plot_structure(r, "output_structure", 10.0)
