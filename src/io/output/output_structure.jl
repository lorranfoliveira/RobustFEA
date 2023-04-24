include("../../../src/fea/fea.jl")

struct OutputStructure
    # [x1 y1
    #  x2 y2
    #  x3 y3]
    nodes::Vector{Vector{Float64}}
    # [node1_id, node2_id]
    elements::Vector{Vector{Int64}}
    areas_of_elements::Vector{Float64}

    function OutputStructure(structure::Structure)
        nodes = extract_nodes(structure)
        elements = extract_elements(structure)
        areas = extract_areas(structure)

        new(nodes, elements, areas)
    end
end

function extract_nodes(structure::Structure)::Vector{Vector{Float64}}
    nodes = Vector{Vector{Float64}}(undef, length(structure.nodes))
    for i=eachindex(structure.nodes)
        nodes[i] = structure.nodes[i].position
    end
    return nodes
end

function extract_elements(structure::Structure)::Vector{Vector{Int64}}
    elements = Vector{Vector{Int64}}(undef, length(structure.elements))
    for i=eachindex(structure.elements)
        elements[i] = [structure.elements[i].nodes[1].id, structure.elements[i].nodes[2].id]
    end
    return elements
end

function extract_areas(structure::Structure)::Vector{Float64}
    areas = Vector{Float64}(undef, length(structure.elements))
    for i=eachindex(structure.elements)
        areas[i] = structure.elements[i].area
    end
    return areas
end
