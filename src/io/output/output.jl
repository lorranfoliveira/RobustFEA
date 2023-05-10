include("../../../src/fea/structure.jl")
include("../../../src/otm/compliance/base_compliance.jl")
include("output_structure.jl")
include("output_compliance.jl")
include("output_iteration.jl")

mutable struct Output
    filename::String
    output_structure::Union{OutputStructure, Nothing}
    output_compliance::Union{OutputCompliance, Nothing}
    output_iterations::Union{Vector{OutputIteration}, Nothing}

    function Output(filename::String="output.json",
        output_structure::Union{OutputStructure, Nothing}=nothing,
        output_compliance::Union{OutputCompliance, Nothing}=nothing,
        output_iterations::Union{Vector{OutputIteration}, Nothing}=nothing)
        
        new(filename, output_structure, output_compliance, output_iterations)
    end
end

function save_json(output::Output)
    open(output.filename, "w") do io
        JSON.print(io, output)
    end
end
