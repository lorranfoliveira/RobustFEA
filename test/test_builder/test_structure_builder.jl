include("../../src/builder/builder.jl")

using Test

@testset verbose=true "Example 3" begin
    builder = StructureBuilder(2.0, 1.0, 3, 2, Material(1, 1.0))
    structure = build(builder)
end
