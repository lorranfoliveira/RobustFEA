include("src/otm/otm.jl")

otm = generate_optimizer(ARGS[1])
#otm = generate_optimizer("examples/hook/case_2.json")
optimize!(otm)
