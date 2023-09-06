include("src/otm/otm.jl")

otm = generate_optimizer(ARGS[1])
optimize!(otm)
