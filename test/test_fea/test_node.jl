include("../../src/fea/node.jl")
using Test

# Test
@testset "Node" begin
    @testset "Constructor" begin
        @test_throws ArgumentError Node(0, [0.0, 0.0], [0.0, 0.0], [false, false])
        @test_throws ArgumentError Node(1, [0.0], [0.0, 0.0], [false, false])
        @test_throws ArgumentError Node(1, [0.0, 0.0], [0.0], [false, false])
        @test_throws ArgumentError Node(1, [0.0, 0.0], [0.0, 0.0], [false])
    end

    @testset "distance" begin
        node1 = Node(1, [0.0, 0.0], [0.0, 0.0], [false, false])
        node2 = Node(2, [1.0, 1.0], [0.0, 0.0], [false, false])
        @test distance(node1, node2) == 1.4142135623730951
    end

    @testset "dofs" begin
        node = Node(2, [0.0, 0.0], [0.0, 0.0], [false, false])
        @test dofs(node) == [3, 4]
    end

    @testset "free_dofs" begin
        node = Node(1, [0.0, 0.0], [0.0, 0.0], [true, false])
        @test free_dofs(node) == [2]
    end

    @testset "free_forces" begin
        node = Node(3, [0.0, 0.0], [10.0, 5.0], [true, false])
        @test free_forces(node) == [5.0]
    end
end