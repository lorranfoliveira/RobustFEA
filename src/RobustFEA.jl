module RobustFEA

include("geometry/geometry.jl")
include("geometry/segment/segment.jl")

export Point, distance, Δx, Δy
export Segment, length, cos, sin, angle

end
