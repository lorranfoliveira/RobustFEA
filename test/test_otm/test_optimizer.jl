include("../../src/otm/otm.jl")
include("../../src/fea/fea.jl")

using Test

@testset verbose = true "Optimizer" begin
    @testset verbose = true "Example 1" begin
        material = Material(1, 1.0)

        nodes = [
            Node(1, [0.0, 0.0]),
            Node(2, [2.0, 0.0]; constraint=[true, true]),
            Node(3, [4.0, 0.0]),
            Node(4, [0.0, 2.0]; constraint=[true, true]),
            Node(5, [2.0, 2.0]; force=[1.0, 1.0]),
            Node(6, [4.0, 2.0]; constraint=[true, true]),
            Node(7, [0.0, 4.0]),
            Node(8, [2.0, 4.0]; constraint=[true, true]),
            Node(9, [4.0, 4.0])
        ]

        elements = [
            Element(1, 1.0, [nodes[1], nodes[2]], material),
            Element(2, 1.0, [nodes[2], nodes[3]], material),
            Element(3, 1.0, [nodes[1], nodes[4]], material),
            Element(4, 1.0, [nodes[2], nodes[5]], material),
            Element(5, 1.0, [nodes[3], nodes[6]], material),
            Element(6, 1.0, [nodes[4], nodes[5]], material),
            Element(7, 1.0, [nodes[5], nodes[6]], material),
            Element(8, 1.0, [nodes[4], nodes[7]], material),
            Element(9, 1.0, [nodes[5], nodes[8]], material),
            Element(10, 1.0, [nodes[6], nodes[9]], material),
            Element(11, 1.0, [nodes[7], nodes[8]], material),
            Element(12, 1.0, [nodes[8], nodes[9]], material)
        ]

        structure = Structure(nodes, elements)

        compliance = ComplianceSmoothPNorm(structure)

        optimizer = Optimizer(compliance)

        optimize!(optimizer)
    end

    @testset verbose = true "Example 2" begin
        material = Material(1, 1.0)

        nodes = [
            Node(1, [0.0, 0.0]; constraint=[true, true]),
            Node(2, [1.0, 0.0]),
            Node(3, [2.0, 0.0]; force=[100.0, 100.0]),
            Node(4, [0.5, 0.5]),
            Node(5, [1.5, 0.5]),
            Node(6, [0.0, 1.0]; constraint=[true, true]),
            Node(7, [1.0, 1.0]),
            Node(8, [2.0, 1.0]; force=[1.0, 1.0])
        ]

        elements = [
            Element(1, 1.0, [nodes[1], nodes[2]], material),
            Element(2, 1.0, [nodes[1], nodes[4]], material),
            Element(3, 1.0, [nodes[1], nodes[6]], material),
            Element(4, 1.0, [nodes[2], nodes[3]], material),
            Element(5, 1.0, [nodes[2], nodes[5]], material),
            Element(6, 1.0, [nodes[2], nodes[7]], material),
            Element(7, 1.0, [nodes[3], nodes[8]], material),
            Element(8, 1.0, [nodes[4], nodes[2]], material),
            Element(9, 1.0, [nodes[4], nodes[7]], material),
            Element(10, 1.0, [nodes[5], nodes[3]], material),
            Element(11, 1.0, [nodes[5], nodes[8]], material),
            Element(12, 1.0, [nodes[6], nodes[4]], material),
            Element(13, 1.0, [nodes[6], nodes[7]], material),
            Element(14, 1.0, [nodes[7], nodes[5]], material),
            Element(15, 1.0, [nodes[7], nodes[8]], material)
        ]

        structure = Structure(nodes, elements)

        compliance = ComplianceSmoothPNorm(structure)

        optimizer = Optimizer(compliance)

        optimize!(optimizer)
    end
end
