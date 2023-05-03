include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 7
ny = 37
lx = 2.0
ly = 6.0

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1e6), connectivity_level=6)
structure = build(builder)

for i=1:nx
    restrict_nearest_node(structure, [(i-1)*(lx/(nx-1)), 0.0], [true, true])
end

load_nearest_node(structure, [lx/2, ly], [1.0, 5.0])

compliance = ComplianceSmoothMu(structure)

vol = 0.05*lx*ly*1/450
#vol = 1.0
optimizer = Optimizer(compliance, max_iters=5000, volume_max=vol, apply_filter=true)

optimize!(optimizer)

r = Plotter("output.json")
plot_optimized_structure(r, 10.0)
