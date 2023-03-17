include("../../../src/RobustFEA.jl")

using Test

using .RobustFEA: Point, distance, Δx, Δy

@testset verbose = true "Point" begin
    @testset "Constructor_1" begin
        p = Point(1.0, 2.0)
        @test p.x == 1.0
        @test p.y == 2.0
    end

    @testset "Constructor_2" begin
        p = Point()
        @test p.x == 0.0
        @test p.y == 0.0
    end

    @testset "Δx" begin
        p1 = Point()
        p2 = Point(3.0, 4.0)
        @test Δx(p1, p2) == 3.0
    end

    @testset "Δy" begin
        p1 = Point()
        p2 = Point(3.0, 4.0)
        @test Δy(p1, p2) == 4.0
    end

    @testset "distance" begin
        p1 = Point()
        p2 = Point(3.0, 4.0)
        @test distance(p1, p2) == 5.0
    end
end
