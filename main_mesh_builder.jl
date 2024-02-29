include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

lx = 80.0
ly = 80.0
nx = 15
ny = 15

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0), connectivity_ratio=20.0)
structure = build(builder)

restrict_nearest_node(structure, [30.0, 30.0], [true, true])
restrict_nearest_node(structure, [30.0, 50.0], [true, true])
restrict_nearest_node(structure, [50.0, 50.0], [true, true])
restrict_nearest_node(structure, [50.0, 30.0], [true, true])

f = [0.1, 1.0]
load_nearest_node(structure, [0.0, 0.0], f)
load_nearest_node(structure, [0.0, 80.0], f)
load_nearest_node(structure, [80.0, 80.0], f)
load_nearest_node(structure, [80.0, 0.0], f)

#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure, p=20.0, unique_loads_angle=false)
#compliance = ComplianceSmoothMu(structure, β=0.0)

vol = 1.0
optimizer = Optimizer(compliance, max_iters=5000, volume_max=vol, filter_tol=0.0, γ=0.5)

optimize!(optimizer)

r = Plotter(optimizer.output.filename)
plot_structure(r, "output_structure", 5.0)

