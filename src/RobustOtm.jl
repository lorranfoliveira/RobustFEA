module RobustFEA

include("geometry/geometry.jl")
include("fea/fea.jl")

# Point
export Point, distance, Δcoords
# Segment
export Segment, length, cos, sin, angle

# Force
export Force, resultant, angle
# Constraint
export Constraint, is_free
# node
export Node, distance, dofs, free_dofs

end
