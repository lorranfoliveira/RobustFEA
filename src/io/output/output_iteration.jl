include("../../../src/fea/fea.jl")

mutable struct OutputIteration
    iter::Int64
    x::Vector
    obj::Float64
    vol::Float64

    function OutputIteration(iter::Int64=0, x::Vector=[], obj::Float64=0.0, vol::Float64=0.0)
        new(iter, x, obj, vol)
    end
end
