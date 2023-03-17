include("src/RobustFEA.jl")

using .RobustFEA

p1 = Point()
p2 = Point(3.0, 4.0)

println(distance(p1, p2))