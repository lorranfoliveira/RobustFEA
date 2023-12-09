include("src/otm/otm.jl")

otm = generate_optimizer(ARGS[1])
#otm = generate_optimizer("flower.json")
optimize!(otm)
