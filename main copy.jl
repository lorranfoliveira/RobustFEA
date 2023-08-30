using JSON

include("src/io/plotter/plotter.jl")

include("src/builder/builder.jl")
include("src/otm/otm.jl")
include("src/fea/fea.jl")

function run(filename::String)
    # =================== Read data ===================
    data = JSON.parsefile(filename)

    # =================== Create structure ===================
    nodes::Vector{Node} = []
    elements::Vector{Element} = []
    materials::Vector{Material} = []

    for material_data in data["initial_structure"]["materials"]
        material = Material(material_data["id"], material_data["young"])
        push!(materials, material)
    end

    for node_data in data["initial_structure"]["nodes"]
        node = Node(node_data["id"], 
                    Vector{Float64}(node_data["position"]), 
                    force=Vector{Float64}(node_data["force"]), 
                    constraint=Vector{Bool}(node_data["support"]))
        push!(nodes, node)
    end

    for element_data in data["initial_structure"]["elements"]
        id = element_data["id"]
        node1 = nodes[element_data["nodes"][1]]
        node2 = nodes[element_data["nodes"][2]]
        material = materials[element_data["material"]]
        element = Element(id, [node1, node2], material, element_data["area"])
        push!(elements, element)
    end

    structure = Structure(nodes, elements)
    
    # =================== Create optimizer ===================
    comp = NaN
    if data["optimizer"]["compliance_type"] == data["optimizer"]["compliance_p_norm"]["key"]
        comp = ComplianceSmoothPNorm(structure, 
                                     p=data["optimizer"]["compliance_p_norm"]["p"],
                                     unique_loads_angle=false)
    elseif data["optimizer"]["compliance_type"] == data["optimizer"]["compliance_nominal"]["key"]
        comp = ComplianceNominal(structure)
    elseif data["optimizer"]["compliance_type"] == data["optimizer"]["compliance_mu"]["key"]
        comp = ComplianceSmoothMu(structure, β=data["optimizer"]["compliance_mu"]["beta"])
    else
        throw(ArgumentError("Invalid compliance type."))
    end

    otm = Optimizer(comp, 
                    filename,
                    volume_max=data["optimizer"]["volume_max"],
                    initial_move_parameter=data["optimizer"]["initial_move_multiplier"],
                    adaptive_move=data["optimizer"]["use_adaptive_move"],
                    min_iters=data["optimizer"]["min_iterations"],
                    max_iters=data["optimizer"]["max_iterations"],
                    x_min=data["optimizer"]["x_min"],
                    tol=data["optimizer"]["tolerance"],
                    γ=data["optimizer"]["initial_damping_parameter"])

    @time optimize!(otm)
end

run("example.json")
