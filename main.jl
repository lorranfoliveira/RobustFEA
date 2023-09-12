include("src/otm/otm.jl")

otm = generate_optimizer(ARGS[1])
<<<<<<< HEAD
#otm = generate_optimizer("examples/hook/case_2.json")
=======
# otm = generate_optimizer("examples/hook/case_2.json")
>>>>>>> 0db2847109cf6e6eb66aeacb843ecaf13e9cdc2c
optimize!(otm)
