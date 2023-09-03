include("src/otm/otm.jl")

otms = [generate_optimizer("final_examples/hook_$i.json") for i in 5:8]

for otm in otms
    optimize!(otm)
end
