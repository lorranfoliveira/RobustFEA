using JSON

include("src/otm/otm.jl")


otm = generate_optimizer("example.json")
optimize!(otm)

