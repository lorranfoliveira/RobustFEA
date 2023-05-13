include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

nx = 9
ny = 9
lx = 2.0
ly = 6.0

# Pegar as forças e testar com o filtro máximo aplicado nas duas direções em que as forças são máximas. Fazer isso para todos os casos

builder = StructureBuilder(lx, ly, nx, ny, Material(1, 1.0), connectivity_ratio=Inf)
structure = build(builder)

restrict_nearest_nodes_inline_x(structure, lx, nx, 0.0, [true, true])

load_nearest_node(structure, [lx/2, ly], [1.0, 1.0])

#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure)

vol = 1.0
optimizer = Optimizer(compliance, max_iters=20000, volume_max=vol, filter_tol=Inf)

optimize!(optimizer)

r = Plotter("output.json")
plot_structure(r, "output_structure", 30.0)
