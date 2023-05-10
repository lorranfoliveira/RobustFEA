include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 7
ny = 37
lx = 2.0
ly = 6.0

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0), connectivity_ratio=5.0)
structure = build(builder)

for i=1:nx
    restrict_nearest_node(structure, [(i - 1)*(lx/(nx - 1)), 0.0], [true, true])
end

load_nearest_node(structure, [lx/2, ly], [1.0, 0.0])

compliance = ComplianceNominal(structure)

vol = 1.0
#vol = 1.0
optimizer = Optimizer(compliance, max_iters=5000, volume_max=vol, filter_tol=0.0)

optimize!(optimizer)

r = Plotter("output.json")
plot_structure(r, "input_structure", 10.0)
