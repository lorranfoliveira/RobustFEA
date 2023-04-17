include("src/RobustOtm.jl")

using GLMakie

nodes = [
    Node(1, [0.0, 4.0], constraint=[true, true]),
    Node(2, [2.0, 4.0]),
    Node(3, [4.0, 4.0], force=[1.0, 1.0]),
    Node(4, [1.0, 5.0]),
    Node(5, [3.0, 5.0]),
    Node(6, [0.0, 6.0], constraint=[true, true]),
    Node(7, [2.0, 6.0]),
    Node(8, [4.0, 6.0], force=[1.0, 1.0])]

material = Material(1, 1.0)

initial_area = 1.0

elements = [
    Element(1, initial_area, [nodes[1], nodes[4]], material),
    Element(2, initial_area, [nodes[1], nodes[6]], material),
    Element(3, initial_area, [nodes[2], nodes[1]], material),
    Element(4, initial_area, [nodes[2], nodes[5]], material),
    Element(5, initial_area, [nodes[3], nodes[2]], material),
    Element(6, initial_area, [nodes[3], nodes[5]], material),
    Element(7, initial_area, [nodes[4], nodes[2]], material),
    Element(8, initial_area, [nodes[4], nodes[7]], material),
    Element(9, initial_area, [nodes[5], nodes[7]], material),
    Element(10, initial_area, [nodes[5], nodes[8]], material),
    Element(11, initial_area, [nodes[6], nodes[4]], material),
    Element(12, initial_area, [nodes[6], nodes[7]], material),
    Element(13, initial_area, [nodes[7], nodes[2]], material),
    Element(14, initial_area, [nodes[7], nodes[8]], material),
    Element(15, initial_area, [nodes[8], nodes[3]], material)]

structure = Structure(nodes, elements)

compliance = Compliance(structure)

println("Smooth obj: $(diff_obj_smooth(compliance))\n\n")
println("obj: $(diff_obj(compliance))\n\n")
println("u: $(u(structure))\n\n")


f = Figure()
Axis(f[1, 1])

xs::Vector{Float64} = []
ys::Vector{Float64} = []

for el in structure.elements
    push!(xs, el.nodes[1].position[1])
    push!(ys, el.nodes[1].position[2])

    push!(xs, el.nodes[2].position[1])
    push!(ys, el.nodes[2].position[2])
end

linesegments!(xs, ys)
f
