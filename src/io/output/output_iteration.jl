include("../../../src/fea/fea.jl")

mutable struct OutputIteration
    iter::Int64
    x::Vector
    min_obj::Float64
    max_obj::Float64
    obj::Float64
    vol::Float64

    function OutputIteration(iter::Int64=0, x::Vector=[], min_obj::Float64=0.0, max_obj::Float64=0.0, obj::Float64=0.0, vol::Float64=0.0)
        new(iter, x, min_obj, max_obj, obj, vol)
    end
end
