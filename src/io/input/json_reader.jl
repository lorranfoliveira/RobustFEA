include("../../../src/fea/fea.jl")

using JSON


struct JsonReader
    data::Dict

    function JsonReader(filename::String)
        new(JSON.parse(read(filename, String)))
    end
end

# ========= structure =========
function structure_data(reader::JsonReader)::Dict
    return reader.data["output_structure"]
end

function nodes_data(reader::JsonReader)::Vector{Vector{Float64}}
    return convert(Vector{Vector{Float64}}, structure_data(reader)["nodes"])
end

function elements_data(reader::JsonReader)::Vector{Vector{Int64}}
    return convert(Vector{Vector{Int64}}, structure_data(reader)["elements"])
end

function final_areas_data(reader::JsonReader)::Vector{Float64}
    return convert(Vector{Float64}, structure_data(reader)["areas_of_elements"])
end

# ========= iterations
function iterations_data(reader::JsonReader)::Vector
    return reader.data["output_iterations"]
end

function its_vol(reader::JsonReader)::Vector{Float64}
    return [it["vol"] for it in iterations_data(reader)]
end

function its_obj(reader::JsonReader)::Vector{Float64}
    return [it["obj"] for it in iterations_data(reader)]
end

function its_x(reader::JsonReader)::Vector{Vector{Float64}}
    return [it["x"] for it in iterations_data(reader)]
end

function its_iter(reader::JsonReader)::Vector{Int64}
    return [it["iter"] for it in iterations_data(reader)]
end

