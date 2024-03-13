include("src/otm/otm.jl")

otm = generate_optimizer(ARGS[1])
#otm = generate_optimizer("example2.json")

#if length(otm.x_k) == 4
#    for i=1:4
#        otm.x_k[i] = otm.x_k[1]/(i/10+1)
#    end
#end

optimize!(otm)

println(obj(otm.compliance))
