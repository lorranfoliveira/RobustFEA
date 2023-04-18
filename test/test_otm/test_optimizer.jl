include("../../src/otm/otm.jl")
include("../../src/fea/fea.jl")

using Test

@testset verbose = true "Optimizer" begin
    @testset verbose = true "Example 1" begin
        nodes = [
            Node(1, [0.0, 2.0]; constraint=[true, true]),
            Node(2, [-2.0, 0.0]; constraint=[true, true]),
            Node(3, [0.0, 0.0]; force=[1.0, 1.0]),
            Node(4, [2, 0.0]; constraint=[true, true]),
            Node(5, [0.0, -2.0]; constraint=[true, true])
            ]

        material = Material(1, 1.0)

        x = [0.1, 0.02, 0.02,  0.1]

        elements = [
            Element(1, x[1], [nodes[1], nodes[3]], material),
            Element(2, x[2], [nodes[2], nodes[3]], material),
            Element(3, x[3], [nodes[3], nodes[4]], material),
            Element(4, x[4], [nodes[5], nodes[3]], material)
        ]

        structure = Structure(nodes, elements)

        compliance = Compliance(structure)

        optimizer = Optimizer(compliance, 1e-6, 1000)
    end
end