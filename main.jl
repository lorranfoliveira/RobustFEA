include("src/otm/otm.jl")

#otm = generate_optimizer(ARGS[1])
otm = generate_optimizer("cross_0.json")
optimize!(otm)
