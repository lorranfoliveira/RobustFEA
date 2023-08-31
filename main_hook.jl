include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

using NPZ, Logging

id = "1_02e-1"
use_lc = false
adaptive_γ = false
beta = 0.2e-1
γ = 0.7
move = 0.1
filename = "hook_$id.json"#114924 with 0.1 #114891 with 100

# Create a logger
io = open(replace("$(filename)", ".json" => "_log.txt"), "w+")
logger = SimpleLogger(io)
global_logger(logger)

# Create structure
npz_data = NPZ.npzread(replace(filename, ".json" => ".npz"))
nodes_numpy = npz_data["arr_0"]
elements_numpy = npz_data["arr_1"] .+ 1
restricted_nodes = npz_data["arr_2"]
loaded_nodes = npz_data["arr_3"]

nodes::Vector{Node} = []
for i = 1:size(nodes_numpy, 1)
    node = Node(i, nodes_numpy[i, :])
    push!(nodes, node)
end

material = Material(1, 1.0)
elements::Vector{Element} = []
for i = 1:size(elements_numpy, 1)
    el1_id, el2_id = elements_numpy[i, :]
    element = Element(i, [nodes[el1_id], nodes[el2_id]], material)
    push!(elements, element)
end

structure = Structure(nodes, elements)

for i = 1:size(restricted_nodes, 1)
    restrict_nearest_node(structure, restricted_nodes[i, :], [true, true])
end

fx = 0.25
fy = 1.0
sz = size(loaded_nodes, 1)

for i = 1:size(loaded_nodes, 1)
    load_nearest_node(structure, loaded_nodes[i, :], [fx, fy] / sz)
end



#load_nearest_node(structure, [-100, 0.0], [fx, fy] / sz)
#load_nearest_node(structure, [100, 0.0], [fx, fy] / sz)

#load_nearest_node(structure, [0.0, -100.0], [fx, fy] / sz)
#load_nearest_node(structure, [0.0, 100.0], [fx, fy] / sz)


#compliance = ComplianceNominal(structure)
#compliance = ComplianceSmoothPNorm(structure, p=15.0, unique_loads_angle=false)
compliance = ComplianceSmoothMu(structure, β=beta)

vol = 1.0
optimizer = Optimizer(compliance,
    max_iters=15000,
    volume_max=vol,
    adaptive_move=adaptive_γ,
    initial_move_parameter=move,
    γ=γ,
    filter_tol=0.0,
    filename=filename,
    layout_constraint_divisions=0)

#γ=0.0
#It: 11839  obj: 95920.67922411361  γ:0.0  θc: -88.90016262672727  vol: 1.0000000053452505  error: 8.171068310100126e-9
#γ=0.1
#It: 12134  obj: 95998.70796692552  γ:0.1  θc: -88.90054893662811  vol: 1.0000000111171548  error: 9.951822426147593e-9
#γ=0.3
#It: 8721  obj: 96109.53913271587  γ:0.3  θc: -88.90769645878345  vol: 1.0000003018951689  error: 9.984771721405416e-9

if use_lc
    try
        optimizer.layout_constraint = npz_data["arr_4"] .+ 1
    catch e
        println("There is no layout constraint.")
        optimizer.layout_constraint = nothing
    end
end

optimize!(optimizer)

close(io)

#@info "Areas: $([e.area for e in structure.elements])"

r = Plotter(filename)
plot_structure(r, "output_structure", 5.0, 1e-2)
#plot_compliance(r)
