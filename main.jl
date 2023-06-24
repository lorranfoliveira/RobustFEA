include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

using NPZ

filename = "quad.json"


# Create structure
npz_data = NPZ.npzread(replace(filename, ".json" => ".npz"))
nodes_numpy = npz_data["arr_0"]
elements_numpy = npz_data["arr_1"] .+ 1
restricted_nodes = npz_data["arr_2"]
loaded_nodes = npz_data["arr_3"]

nodes::Vector{Node} = []
for i=1:size(nodes_numpy, 1)
    node = Node(i, nodes_numpy[i, :])
    push!(nodes, node)
end

material = Material(1, 1.0)
elements::Vector{Element} = []
for i=1:size(elements_numpy, 1)
    el1_id, el2_id = elements_numpy[i, :]
    element = Element(i, [nodes[el1_id], nodes[el2_id]], material)
    push!(elements, element)
end

structure = Structure(nodes, elements)

for i=1:size(restricted_nodes, 1)
    restrict_nearest_node(structure, restricted_nodes[i, :], [true, true])
end

sz = size(loaded_nodes, 1)
for i=1:size(loaded_nodes, 1)
    load_nearest_node(structure, loaded_nodes[i, :], [1.0, 1.0] / sz)
end


#compliance = ComplianceNominal(structure)
compliance = ComplianceSmoothPNorm(structure, p=30.0)
#compliance = ComplianceSmoothMu(structure, β=0.2)

vol = 1.0
optimizer = Optimizer(compliance, max_iters=10000, volume_max=vol, filter_tol=0.0, filename=filename)
optimizer.layout_constraint = reshape(npz_data["arr_4"] .+ 1, 1, length(npz_data["arr_4"]))

optimize!(optimizer)

r = Plotter(filename)
plot_structure(r, "output_structure", 20.0)
#plot_compliance(r)
