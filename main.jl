include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")


builder = StructureBuilder(8.0, 4.0, 5, 5, Material(1, 1.0))
structure = build(builder)

restrict_nearest_node(structure, [0.0, 2.0], [true, true])
restrict_nearest_node(structure, [8.0, 2.0], [true, true])

load_nearest_node(structure, [4.0, 2.0], [1.0, 1.0])

compliance = ComplianceSmoothPNorm(structure)

optimizer = Optimizer(compliance)

optimize!(optimizer)

r = Plotter("output.json")
plot_optimized_structure(r, 10.0)
