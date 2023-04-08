using Test

include("../../src/fea/constraint.jl")


@testset verbose = true "Constraint" begin
    @testset "Constructor_1" begin
        c = Constraint(true, false)
        @test c.dofs[1] == true
        @test c.dofs[2] == false
    end

    @testset "Constructor_2" begin
        c = Constraint()
        @test c.dofs[1] == false
        @test c.dofs[2] == false
    end

    @testset "is_free" begin
        c = Constraint(true, false)
        @test is_free(c) == false
    end
end