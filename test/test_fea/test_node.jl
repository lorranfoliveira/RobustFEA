include("../../src/fea/node.jl")
using Test


# Test
@testset "Node" begin
    @testset "distance" begin
        node1 = Node(1, Point(0.0, 0.0), Force(0.0, 0.0), Constraint(true, true))
        node2 = Node(2, Point(1.0, 1.0), Force(0.0, 0.0), Constraint(true, true))
        @test distance(node1, node2) == sqrt(2)
    end
    @testset "dofs" begin
        node = Node(1, Point(0.0, 0.0), Force(0.0, 0.0), Constraint(true, true))
        @test dofs(node) == [1, 2]
    end
    @testset "free_dofs" begin
        node1 = Node(1, Point(0.0, 0.0), Force(0.0, 0.0), Constraint(true, true))
        @test free_dofs(node1) == [1, 2]

        node2 = Node(1, Point(0.0, 0.0), Force(0.0, 0.0), Constraint(false, true))
        @test free_dofs(node2) == [2]
    end
end