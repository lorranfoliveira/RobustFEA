include("../../src/otm/otm.jl")
include("../../src/fea/fea.jl")
include("../../src/builder/structure_builder.jl")


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
            Element(1, [nodes[1], nodes[2]], material),
            Element(2, [nodes[2], nodes[3]], material),
            Element(3, [nodes[1], nodes[4]], material),
            Element(4, [nodes[2], nodes[5]], material),
            Element(5, [nodes[3], nodes[6]], material),
            Element(6, [nodes[4], nodes[5]], material),
            Element(7, [nodes[5], nodes[6]], material),
            Element(8, [nodes[4], nodes[7]], material),
            Element(9, [nodes[5], nodes[8]], material),
            Element(10, [nodes[6], nodes[9]], material),
            Element(11, [nodes[7], nodes[8]], material),
            Element(12, [nodes[8], nodes[9]], material)
        ]

        structure = Structure(nodes, elements)

        compliance = ComplianceSmoothPNorm(structure)

        optimizer = Optimizer(compliance)

        optimize!(optimizer)

        println("")
    end

    @testset verbose = true "Example 2" begin
        material = Material(1, 1.0)

        nodes = [
            Node(1, [0.0, 0.0]; constraint=[true, true]),
            Node(2, [1.0, 0.0]),
            Node(3, [2.0, 0.0]; force=[1.0, 1.0]),
            Node(4, [0.5, 0.5]),
            Node(5, [1.5, 0.5]),
            Node(6, [0.0, 1.0]; constraint=[true, true]),
            Node(7, [1.0, 1.0]),
            Node(8, [2.0, 1.0]; force=[1e-10, 1e-10])
        ]

        elements = [
            Element(1, [nodes[1], nodes[2]], material),
            Element(2, [nodes[1], nodes[4]], material),
            Element(3, [nodes[1], nodes[6]], material),
            Element(4, [nodes[2], nodes[3]], material),
            Element(5, [nodes[2], nodes[5]], material),
            Element(6, [nodes[2], nodes[7]], material),
            Element(7, [nodes[3], nodes[8]], material),
            Element(8, [nodes[4], nodes[2]], material),
            Element(9, [nodes[4], nodes[7]], material),
            Element(10, [nodes[5], nodes[3]], material),
            Element(11, [nodes[5], nodes[8]], material),
            Element(12, [nodes[6], nodes[4]], material),
            Element(13, [nodes[6], nodes[7]], material),
            Element(14, [nodes[7], nodes[5]], material),
            Element(15, [nodes[7], nodes[8]], material)
        ]

        structure = Structure(nodes, elements)

        compliance = ComplianceSmoothPNorm(structure)

        optimizer = Optimizer(compliance)

        optimize!(optimizer)

        println("")
    end
end
