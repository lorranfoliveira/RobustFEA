using Test

include("../../src/fea/fea.jl")

@testset "Material" begin
    @testset "constructor" begin
        @test_throws ErrorException Material(0, 1.0)
        @test_throws ErrorException Material(1, 0.0)
        @test Material(1, 1.0) isa Material

        material = Material(2, 1.0)
        @test material.id == 2
        @test material.young == 1.0
    end
end