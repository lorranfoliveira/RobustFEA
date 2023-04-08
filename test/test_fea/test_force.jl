using Test

include("../../src/fea/force.jl")

@testset verbose = true "Force" begin
    @testset "Constructor_1" begin
        f = Force(1.0, 2.0)
        @test f.forces[1] == 1.0
        @test f.forces[2] == 2.0
    end

    @testset "Constructor_2" begin
        f = Force()
        @test f.forces[1] == 0.0
        @test f.forces[2] == 0.0
    end

    @testset "resultant" begin
        f = Force(3.0, 4.0)
        @test resultant(f) == 5.0
    end

    @testset "angle" begin
        f = Force(3.0, 4.0)
        @test angle(f) == atan(4.0, 3.0)
    end
end