include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")


nodes = [
    Node(1, [0.0, 0.0]; constraint=[true, true]),
    Node(2, [0.0, 1.0]; constraint=[true, true]),
    Node(3, [1.0, 0.0]),
    Node(4, [1.0, 1.0]),
    Node(5, [2.0, 0.0]),
    Node(6, [2.0, 1.0]; force=[1.0, 1.0])
]

material = Material(1, 1.0)

area = 1.0
elements::Vector{Element} = []

els_ids = [[1,2],
           [3,4],
           [5,6],
           [1,3],
           [3,5],
           [2,4],
           [4,6],
           [1,4],
           [3,6],
           [2,3],
           [4,5]]

for i=eachindex(els_ids)
    n1 = nodes[els_ids[i][1]]
    n2 = nodes[els_ids[i][2]]

    push!(elements, Element(i, [n1, n2], material, area))
end

structure = Structure(nodes, elements)

println("Displacements: $(u(structure))")

comp = ComplianceNominal(structure)

otm = Optimizer(comp, 
                max_iters=500,
                volume_max=1.0, 
                adaptive_move=false, 
                initial_move_parameter=0.1, 
                γ=0.0, 
                filter_tol=0.0, 
                filename="test_rto_cpp.json",
                layout_constraint_divisions=0)

@time optimize!(otm)