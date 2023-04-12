using Test

include("../../src/otm/otm.jl")
include("../../src/fea/fea.jl")

@testset verbose=true "Compliance" begin
    nodes = [
        Node(1, [1.0, -1.0]; constraint=[true, true]),
        Node(2, [3.0, -1.0]),
        Node(3, [5.0, -1.0]),
        Node(4, [7.0, -1.0]; constraint=[true, true]),
        Node(5, [3.0, 1.0]; forces=[10.0, -5.0]),
        Node(6, [5.0, 1.0])
    ]

    material = Material(1, 100e6)

    area = 0.0014
    elements = [
        Element(1, area, [nodes[1], nodes[2]], material),
        Element(2, area, [nodes[1], nodes[5]], material),
        Element(3, area, [nodes[2], nodes[3]], material),
        Element(4, area, [nodes[2], nodes[6]], material),
        Element(5, area, [nodes[4], nodes[3]], material),
        Element(6, area, [nodes[5], nodes[2]], material),
        Element(7, area, [nodes[5], nodes[6]], material),
        Element(8, area, [nodes[6], nodes[3]], material),
        Element(9, area, [nodes[6], nodes[4]], material)
    ]

    structure = Structure(nodes, elements)

    compliance = Compliance(structure)

    @testset "H" begin
        h = H(compliance)
        r = spzeros(8, 2)
        r[5, 1] = 1.0
        r[6, 2] = 1.0
        @test h ≈ r
    end

    @testset "Z" begin
        @test Z(compliance) ≈ [3.174603153408803e-6 -3.174603153408805e-6
                              -4.232804175368175e-6 3.1170205087808737e-5
                              1.58730157543174e-6 -1.5873015754317396e-6
                              -5.291005077314921e-7 1.3997800881266246e-5
                              2.246340950073356e-5 -8.994708918632216e-6
                              -8.994708918632211e-6 3.593210987426833e-5
                              1.2939600008728084e-5 5.291005085799296e-7
                              -5.291005085799325e-7 1.3997800903712467e-5]
    end
end 