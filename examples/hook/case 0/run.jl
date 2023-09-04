include("../../../src/otm/otm.jl")

otm = generate_optimizer("case_0.json")
optimize!(otm)
