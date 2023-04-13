include("../../src/fea/node.jl")
using Test

# Test
@testset "Node" begin
    @testset "Constructor" begin
        @test_throws ArgumentError Node(0, [0.0, 0.0])
        @test_throws ArgumentError Node(1, [0.0])
        @test_throws ArgumentError Node(1, [0.0, 0.0]; force=[0.0])
        @test_throws ArgumentError Node(1, [0.0, 0.0]; constraint=[false])
    end

    @testset "distance" begin
        node1 = Node(1, [0.0, 0.0])
        node2 = Node(2, [1.0, 1.0])
        @test distance(node1, node2) == 1.4142135623730951
    end

    @testset "dofs" begin
        node1 = Node(2, [0.0, 0.0]; constraint=[true, false])
        node2 = Node(3, [0.0, 0.0]; constraint=[false, true])

        @test dofs(node1) == [4]
        @test dofs(node2) == [5]
        @test dofs(node1, local_dofs=true) == [2]
        @test dofs(node2, local_dofs=true) == [1]
        @test dofs(node1, include_restricted=true) == [3, 4]
        @test dofs(node2, include_restricted=true) == [5, 6]
        @test dofs(node1, include_restricted=true, local_dofs=true) == [1, 2]
        @test dofs(node2, include_restricted=true, local_dofs=true) == [1, 2]

        node3 = Node(3, [0.0, 0.0]; constraint=[true, true])
        @test dofs(node3) == []
        @test dofs(node3, local_dofs=true) == []
        @test dofs(node3, include_restricted=true) == [5, 6]
        @test dofs(node3, include_restricted=true, local_dofs=true) == [1, 2]

        node4 = Node(4, [0.0, 0.0]; constraint=[false, false])
        @test dofs(node4) == [7, 8]
        @test dofs(node4, local_dofs=true) == [1, 2]
        @test dofs(node4, include_restricted=true) == [7, 8]
        @test dofs(node4, include_restricted=true, local_dofs=true) == [1, 2]
    end

    @testset "restricted_dofs" begin
        node1 = Node(2, [0.0, 0.0]; constraint=[true, false])
        @test restricted_dofs(node1) == [3]
        @test restricted_dofs(node1, local_dofs=true) == [1]
        
        node2 = Node(3, [0.0, 0.0]; constraint=[false, true])
        @test restricted_dofs(node2) == [6]
        @test restricted_dofs(node2, local_dofs=true) == [2]

        node3 = Node(3, [0.0, 0.0]; constraint=[true, true])
        @test restricted_dofs(node3) == [5, 6]
        @test restricted_dofs(node3, local_dofs=true) == [1, 2]
    end

    @testset "forces" begin
        node1 = Node(2, [0.0, 0.0]; force=[5.0, 0.0], constraint=[false, false])
        @test forces(node1, exclude_zeros=true) == [5.0]
        @test forces(node1, exclude_zeros=false) == [5.0, 0.0]

        node2 = Node(3, [0.0, 0.0]; force=[0.0, 5.0], constraint=[false, false])
        @test forces(node2, exclude_zeros=true) == [5.0]
        @test forces(node2, exclude_zeros=false) == [0.0, 5.0]

        node3 = Node(3, [0.0, 0.0]; force=[0.0, 0.0], constraint=[false, true])
        @test forces(node3, exclude_zeros=true) == []
        @test forces(node3, exclude_zeros=false) == [0.0]
    end
end