include("../../src/io/output_optimizer.jl")
include("../../src/fea/fea.jl")
include("../../src/otm/otm.jl")
include("../../src/builder/builder.jl")


using Test, JSON

@testset verbose=true "Example 1" begin
    builder = StructureBuilder(2.0, 1.0, 3, 2, Material(1, 1.0))
    structure = build(builder)

    restrict_nearest_node(structure, [0.0, 0.0], [true, true])
    restrict_nearest_node(structure, [0.0, 1.0], [true, true])
    load_nearest_node(structure, [2.0, 0.0], [1.0, 1.0])

    compliance = ComplianceSmoothPNorm(structure)

    optimizer = Optimizer(compliance)

    optimize!(optimizer)

    @test obj(optimizer.compliance) ≈ 68.00018218783981
end
