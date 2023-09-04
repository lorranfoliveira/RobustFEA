include("../../src/otm/otm.jl")

otm = generate_optimizer("example_1.json")
optimize!(otm)
