using Test

include("../../../src/otm/otm.jl")
include("../../../src/fea/fea.jl")


@testset verbose = true "Compliance" begin
    # Insert cross data example
    @testset verbose = true "Example 1" begin
        nodes = [
            Node(1, [0.0, 2.0]; constraint=[true, true]),
            Node(2, [-2.0, 0.0]; constraint=[true, true]),
            Node(3, [0.0, 0.0]; force=[1.0, 1.0]),
            Node(4, [2, 0.0]; constraint=[true, true]),
            Node(5, [0.0, -2.0]; constraint=[true, true])
            ]

        material = Material(1, 1.0)

        x = [0.1, 0.02, 0.02,  0.1]

        elements = [
            Element(1, x[1], [nodes[1], nodes[3]], material),
            Element(2, x[2], [nodes[2], nodes[3]], material),
            Element(3, x[3], [nodes[3], nodes[4]], material),
            Element(4, x[4], [nodes[5], nodes[3]], material)
        ]

        structure = Structure(nodes, elements)

        compliance = ComplianceSmoothPNorm(structure)

        @testset "H" begin
            h = H(compliance.base)
            r = spzeros(10, 2)
            r[5, 1] = 1.0
            r[6, 2] = 1.0
            @test h ≈ r
        end

        @testset "C" begin
            @test C(compliance.base) ≈ [50.0 0.0
                                0.0 10.0]
        end

        @testset "diff_C" begin
            @test diff_C(compliance.base) ≈ [[-4.686749292697808e-30 1.5308084934232806e-14; 1.5308084934232806e-14 -49.999999939999995], 
                                        [-1249.9999924999997 0.0; 0.0 0.0], 
                                        [-1249.9999924999997 0.0; 0.0 0.0], 
                                        [-4.686749292697808e-30 -1.5308084934232806e-14; -1.5308084934232806e-14 -49.999999939999995]]
        end

        @testset "diff_eigenvals" begin
            calculate_C_eigenvals_and_eigenvecs(compliance.base)
            @test diff_eigenvals(compliance.base) ≈ [-49.999999939999995 0.0 0.0 -49.999999939999995; 
                                                -4.686749292697808e-30 -1249.9999924999997 -1249.9999924999997 -4.686749292697808e-30]
        end

        @testset "diff_obj_smooth" begin
            @test diff_obj(compliance) ≈ [-0.07997952656806127, -1249.6800846305637, -1249.6800846305637, -0.07997952656806127]
        end
    end


    @testset verbose = true "Example 2" begin

        nodes = [
            Node(1, [1.0, -1.0]; constraint=[true, true]),
            Node(2, [3.0, -1.0]),
            Node(3, [5.0, -1.0]),
            Node(4, [7.0, -1.0]; constraint=[true, true]),
            Node(5, [3.0, 1.0]; force=[10.0, -5.0]),
            Node(6, [5.0, 1.0])
        ]
        
        material = Material(1, 100e6)
        
        area = 0.0014
        elements = [
            Element(1, area, [nodes[1], nodes[2]], material),
            Element(2, area, [nodes[1], nodes[5]], material),
            Element(3, area, [nodes[2], nodes[3]], material),
            Element(4, area, [nodes[2], nodes[6]], material),
            Element(5, area, [nodes[4], nodes[3]], material),
            Element(6, area, [nodes[5], nodes[2]], material),
            Element(7, area, [nodes[5], nodes[6]], material),
            Element(8, area, [nodes[6], nodes[3]], material),
            Element(9, area, [nodes[6], nodes[4]], material)
        ]
        
        structure = Structure(nodes, elements)
        
        compliance = ComplianceSmoothPNorm(structure)
        
        @testset "H" begin
            h = H(compliance.base)
            r = spzeros(12, 2)
            r[9, 1] = 1.0
            r[10, 2] = 1.0
            jj = 10
            @test h ≈ r
        end
        
        @testset "Z" begin
            @test Z(compliance.base) ≈ [0.0 0.0; 0.0 0.0; 
                                3.174603153408803e-6 -3.174603153408803e-6; 
                                -4.232804175368175e-6 3.117020508780873e-5; 
                                1.58730157543174e-6 -1.5873015754317396e-6; 
                                -5.291005077314921e-7 1.3997800881266246e-5; 
                                0.0 0.0; 
                                0.0 0.0; 
                                2.246340950073356e-5 -8.994708918632216e-6; 
                                -8.994708918632211e-6 3.593210987426833e-5; 
                                1.2939600008728084e-5 5.291005085799296e-7; 
                                -5.291005085799325e-7 1.3997800903712467e-5]
        end
        
        @testset "C" begin
            @test C(compliance.base) ≈ [2.2463409500733556e-5 -8.99470891863221e-6; 
                                -8.994708918632213e-6 3.593210987426832e-5]
        end
        
        @testset "diff_K_element" begin
            @test diff_K(elements[1]) ≈ sparse([0.0 0.0 0.0 0.0; 
                                                0.0 0.0 0.0 0.0; 
                                                0.0 0.0 5.0e7 0.0; 
                                                0.0 0.0 0.0 0.0])
        end
    end

end