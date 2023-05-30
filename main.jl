include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 5
ny = 5
lx = 8.0
ly = 4.0
filename = "beam.json"

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0))
structure = build(builder)

restrict_nearest_node(structure, [0.0, 0.0], [true, true])
restrict_nearest_node(structure, [0.0, ly], [true, true])

load_nearest_node(structure, [lx/2, ly/2], [1.0, 1.0])

#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure, p=20.0)

vol = 1.0
optimizer = Optimizer(compliance, max_iters=10000, volume_max=vol, filter_tol=0.1, filename=filename)

optimize!(optimizer)

r = Plotter(filename)
plot_structure(r, "output_structure", 40.0)
