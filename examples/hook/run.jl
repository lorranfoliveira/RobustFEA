include("../../../src/otm/otm.jl")

for i=1:4
    otm = generate_optimizer("case_$i.json")
    optimize!(otm)
end
