include("../../src/fea/node.jl")
using Test


# Test
@testset "Node" begin
    @testset "resultant_force" begin
        node = Node(1, Point(0.0, 0.0), Force(1.0, 1.0), Constraint())
        @test resultant(node.force) == sqrt(2.0)
    end

    @testset "distance" begin
        node1 = Node(1, Point(0.0, 0.0), Force(), Constraint())
        node2 = Node(2, Point(1.0, 1.0), Force(), Constraint())
        @test distance(node1, node2) == sqrt(2.0)
    end
    @testset "dofs" begin
        node = Node(1, Point(0.0, 0.0), Force(), Constraint())
        @test dofs(node) == [1, 2]
    end
    @testset "free_dofs" begin
        node = Node(1, Point(0.0, 0.0), Force(), Constraint())
        @test free_dofs(node) == [1, 2]
    end
end