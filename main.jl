include("src/otm/otm.jl")

#otm = generate_optimizer(ARGS[1])
otm = generate_optimizer("example2.json")
optimize!(otm)

println(obj(otm.compliance))
