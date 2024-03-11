
using JuMP, NLopt

function solve()
    x_min = -10.0
    x_max = 10.0

    C(x...) = x[1]^2+2*x[1]*x[2]+3*x[2]^2+4*x[1]+5*x[2]+6

    function C_grad(g::AbstractVector, x...)
        g[1] = 2*x[1] + 2*x[2] + 4
        g[2] = 2*x[1] + 6*x[2] + 5
        return
    end

    model = Model(NLopt.Optimizer)
    set_optimizer_attribute(model, "algorithm", :LD_MMA)
    set_optimizer_attribute(model, "print_level", 7)

    JuMP.register(model, :C, 2, C, C_grad; autodiff=false)

    JuMP.@variable(model, x_min <= x[i=1:2] <= x_max)

    JuMP.@NLobjective(model, Min, C(x...))
    JuMP.optimize!(model)

    solution_summary(model; verbose = true)
end

solve()