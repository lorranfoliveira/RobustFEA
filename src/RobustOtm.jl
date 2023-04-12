module RobustFEA

include("fea/fea.jl")

# Point
export Point, distance, Δcoords

# node
export Node, distance, dofs, free_dofs

end
