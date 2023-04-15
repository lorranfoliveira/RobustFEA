using Test

include("../../src/otm/otm.jl")
include("../../src/fea/fea.jl")

@testset verbose=true "Compliance" begin
    nodes = [
        Node(1, [1.0, -1.0]; constraint=[true, true]),
        Node(2, [3.0, -1.0]),
        Node(3, [5.0, -1.0]),
        Node(4, [7.0, -1.0]; constraint=[true, true]),
        Node(5, [3.0, 1.0]; force=[10.0, -5.0]),
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
        r = spzeros(12, 2)
        r[9, 1] = 1.0
        r[10, 2] = 1.0
        jj = 10
        @test h ≈ r
    end

    @testset "Z" begin
        @test Z(compliance) ≈ [1415.8112857026751 -257.4202625215119; 
                                1544.5214867100374 2917.429568107795; 
                                1415.8112855284592 -257.4202668188406; 
                                514.8404925677751 2145.1688202038395; 
                                1415.8112837862989 -257.4202669349845; 
                                -514.8404910122204 1372.908044950849; 
                                1415.8112839605146 -257.4202673995606; 
                                -1544.521481495947 600.6472833459052; 
                                2445.4922885454816 514.8404891183926; 
                                514.840489780319 2145.168827637057; 
                                2445.4922796604646 514.8404937641535; 
                                -514.8404917090844 1372.9080468091536]
    end
end 