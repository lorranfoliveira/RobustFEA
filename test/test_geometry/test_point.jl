using Test

include("../../src/geometry/point.jl")

@testset verbose = true "Point" begin
    @testset "Constructor_1" begin
        p = Point(1.0, 2.0)
        @test p.coords[1] == 1.0
        @test p.coords[2] == 2.0
    end

    @testset "Constructor_2" begin
        p = Point()
        @test p.coords[1] == 0.0
        @test p.coords[2] == 0.0
    end

    @testset "Δcoords" begin
        p1 = Point(1.1, 2.9)
        p2 = Point(3.0, 4.0)
        @test Δcoords(p1, p2) == [1.9, 1.1]
    end

    @testset "distance" begin
        p1 = Point()
        p2 = Point(3.0, 4.0)
        @test distance(p1, p2) == 5.0
    end
end