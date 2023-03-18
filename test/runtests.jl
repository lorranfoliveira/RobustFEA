include("../src/RobustFEA.jl")

using Test

# ======================================
# Point
# ======================================
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


# ======================================
# Segment
# ======================================
using .RobustFEA: Segment, length, cos, sin, angle

@testset verbose = true "Segment" begin

    @testset "Constructor_1" begin
        p1 = Point(1.0, 2.0)
        p2 = Point(3.0, 4.0)
        s = Segment(p1, p2)

        @test s.p1.x == 1.0
        @test s.p1.y == 2.0
        @test s.p2.x == 3.0
        @test s.p2.y == 4.0
    end

    @testset "Constructor_2" begin
        s = Segment(1.0, 2.0, 3.0, 4.0)

        @test s.p1.x == 1.0
        @test s.p1.y == 2.0
        @test s.p2.x == 3.0
        @test s.p2.y == 4.0
    end

    @testset "length" begin
        s = Segment(1.0, 2.0, 3.0, 4.0)

        @test length(s) == 2.8284271247461903
    end

    @testset "cos" begin
        s = Segment(1.0, 2.0, 3.0, 4.0)
        @test cos(s) == 0.7071067811865475
    end

    @testset "sin" begin
        s = Segment(1.0, 2.0, 3.0, 4.0)
        @test sin(s) == 0.7071067811865475
    end

    @testset "angle" begin
        s = Segment(1.0, 2.0, 3.0, 4.0)
        @test angle(s) == 0.7853981633974483
    end
end