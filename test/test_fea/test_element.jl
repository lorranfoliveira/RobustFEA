using Test

include("../../src/fea/fea.jl")

@testset verbose=true "Element" begin
    # Nodes
    nodes = [
        Node(1, [1.0, -1.0], [0.0, 0.0], [true, true]),
        Node(5, [3.0, 1.0], [10.0, -5.0], [false, false])
        ]
    
    element = Element(2, 0.0014, [nodes[1], nodes[2]], Material(1, 100e6))

    # Material
    material = Material(1, 1.0)

    # Element
    @testset "Constructor_errors" begin
        @test_throws ArgumentError Element(0, 1.0, [nodes[1], nodes[2]], material)
        @test_throws ArgumentError Element(1, -1.0, [nodes[1], nodes[2]], material)
        @test_throws ArgumentError Element(1, 1.0, [nodes[1], nodes[1]], material)
    end

    @testset "Constructor" begin
        @test element.id == 2
        @test element.area == 0.0014
        @test element.nodes == [nodes[1], nodes[2]]
        @test element.material == Material(1, 100e6)
    end

    @testset "len" begin
        @test len(element) ≈ 2.8284271247461903
    end

    @testset "dofs" begin
        @test dofs(element) == [1, 2, 9, 10]
    end

    @testset "forces" begin
        @test forces(element) == [0.0, 0.0, 10.0, -5.0]
    end

    @testset "angle" begin
        @test angle(element) ≈ π/4
    end

    @testset "rotation_matrix" begin
        @test rotation_matrix(element) ≈ [
            √2/2 √2/2 0 0
            -√2/2 √2/2 0 0
            0 0 √2/2 √2/2
            0 0 -√2/2 √2/2
        ]
    end

    @testset "stiffness_local" begin
        @test stiffness_local(element) ≈ [
                49497.474683058324 0 -49497.474683058324 0
                0 0 0 0
                -49497.474683058324 0 49497.474683058324 0
                0 0 0 0
            ]
    end

    @testset "stiffness_global" begin
        @test stiffness_global(element) ≈ [
            24748.737341529166 24748.737341529162 -24748.737341529166 -24748.737341529162
            24748.73734152916 24748.737341529155 -24748.73734152916 -24748.737341529155
            -24748.737341529166 -24748.737341529162 24748.737341529166 24748.737341529162
            -24748.73734152916 -24748.737341529155 24748.73734152916 24748.737341529155
        ]
    end
end
