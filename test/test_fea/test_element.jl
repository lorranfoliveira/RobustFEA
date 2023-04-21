using Test

include("../../src/fea/fea.jl")

@testset verbose=true "Element" begin
    # Nodes
    nodes = [
        Node(1, [1.0, -1.0]; constraint=[true, true]),
        Node(5, [3.0, 1.0]; force=[10.0, -5.0])
        ]
    
    element = Element(2, [nodes[1], nodes[2]], Material(1, 100e6), 0.0014)

    # Material
    material = Material(1, 1.0)

    # Element
    @testset "Constructor_errors" begin
        @test_throws ArgumentError Element(0, [nodes[1], nodes[2]], material, 1.0)
        @test_throws ArgumentError Element(1, [nodes[1], nodes[2]], material, -1.0)
        @test_throws ArgumentError Element(1, [nodes[1], nodes[1]], material)
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

    @testset "constraint" begin
        @test constraint(element) == [true, true, false, false]

        element2 = Element(2, [nodes[2], nodes[1]], Material(1, 100e6), 0.0014)
        @test constraint(element2) == [false, false, true, true]
    end

    @testset "free_loaded_dofs" begin
        @test free_loaded_dofs(element) == [9, 10]
        @test free_loaded_dofs(element, local_dofs=true) == [3, 4]

        element2 = Element(2, [nodes[2], nodes[1]], Material(1, 100e6), 0.0014)
        @test free_loaded_dofs(element2) == [9, 10]
        @test free_loaded_dofs(element2, local_dofs=true) == [1, 2]
    end

    @testset "dofs" begin
        @test dofs(element, include_restricted=true) == [1, 2, 9, 10]
        @test dofs(element, include_restricted=true, local_dofs=true) == [1, 2, 3, 4]
        @test dofs(element, include_restricted=false) == [9, 10]
        @test dofs(element, include_restricted=false, local_dofs=true) == [3, 4]
    end

    @testset "forces" begin
        @test forces(element) == [10.0, -5.0]
        @test forces(element, include_restricted=true) == [0.0, 0.0, 10.0, -5.0]
        @test forces(element, include_restricted=false) == [10.0, -5.0]
        @test forces(element, include_restricted=false, exclude_zeros=true) == [10.0, -5.0]
        @test forces(element, include_restricted=true, exclude_zeros=true) == [10.0, -5.0]
    end

    @testset "volume" begin 
        @test volume(element) ≈ 0.0014*2.8284271247461903
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

    @testset "K_local" begin
        @test K_local(element) ≈ [
                49497.474683058324 0 -49497.474683058324 0
                0 0 0 0
                -49497.474683058324 0 49497.474683058324 0
                0 0 0 0
            ]
    end

    @testset "K" begin
        @test K(element) ≈ [
            24748.737341529166 24748.737341529162 -24748.737341529166 -24748.737341529162
            24748.73734152916 24748.737341529155 -24748.73734152916 -24748.737341529155
            -24748.737341529166 -24748.737341529162 24748.737341529166 24748.737341529162
            -24748.73734152916 -24748.737341529155 24748.73734152916 24748.737341529155
        ]
    end
end
