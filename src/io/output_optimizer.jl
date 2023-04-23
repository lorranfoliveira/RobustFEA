include("../../src/fea/fea.jl")

mutable struct OutputIteration
    iter::Int64
    x::Vector
    obj::Float64
    vol::Float64

    function OutputIteration(iter::Int64=0, x::Vector=[], obj::Float64=0.0, vol::Float64=0.0)
        new(iter, x, obj, vol)
    end
end

mutable struct OutputOptimizer
    filename::String
    elements::Vector{Element}
    iterations::Vector

    function OutputOptimizer(filename::String, elements::Vector{Element}, iterations::Vector=[])
        new(filename, elements, iterations)
    end
end

function save_json(otp::OutputOptimizer)
    open(otp.filename, "w") do io
        JSON.print(io, otp)
    end
end
