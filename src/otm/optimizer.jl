include("compliance/compliance.jl")

mutable struct Optimizer
    # manual
    compliance::T where T<:Compliance
    volume_max::Float64
    adaptive_move::Bool
    min_iters::Int64
    max_iters::Int64
    x_min::Float64
    tol::Float64

    # automatic
    x_max::Float64
    x_init::Float64
    move::Vector{Float64}
    iter::Int64
    n::Int64

    x_k::Vector{Float64}
    x_km1::Vector{Float64}
    x_km2::Vector{Float64}

    df_obj_k::Vector{Float64}
    df_vol::Vector{Float64}

    function Optimizer(compliance::T; volume_max::Float64=1.0, 
                                      adaptive_move::Bool=true, 
                                      min_iters::Int64=10,
                                      max_iters::Int64=10000, 
                                      x_min::Float64=0.0, 
                                      tol::Float64=1e-6) where T<:Compliance

        els_len = [len(el) for el in compliance.base.structure.elements]
        n = length(compliance.base.structure.elements)

        x_max =  volume_max / minimum(els_len)
        x_init = volume_max / sum(els_len)
        move = fill(x_init, n)
        iter = 1

        x_k = fill(x_init, n)
        x_km1 = zeros(n)
        x_km2 = zeros(n)

        df_obj_k = zeros(n)
        df_vol_init = zeros(n)

        new(compliance, 
            volume_max,
            adaptive_move, 
            min_iters,
            max_iters, 
            x_min, 
            tol, 
            x_max, 
            x_init, 
            move, 
            iter, 
            n, 
            x_k, 
            x_km1, 
            x_km2, 
            df_obj_k,
            df_vol_init)
    end
end

get_areas(opt::Optimizer)::Vector{Float64} = [el.area for el in opt.compliance.base.structure.elements]

function set_areas(opt::Optimizer)
    for i=eachindex(opt.compliance.base.structure.elements)
        opt.compliance.base.structure.elements[i].area = opt.x_k[i]
    end
end

diff_vol(opt::Optimizer) = [len(el) for el in opt.compliance.base.structure.elements]

function update_move!(opt::Optimizer)
    move_tmp = opt.move[:]

    terms = (opt.x_k - opt.x_km1) .* (opt.x_km1 - opt.x_km2)
    for i=eachindex(terms)
        if terms[i] < 0
            move_tmp[i] = 0.95 * opt.move[i]
        elseif terms[i] > 0
            move_tmp[i] = 1.05 * opt.move[i]
        end
    end

    opt.move = max.(1e-4 * opt.x_init, min.(move_tmp, 10 * opt.x_init))
end

function update_x!(opt::Optimizer)
    vol = volume(opt.compliance.base.structure)
    opt.df_obj_k = diff_obj(opt.compliance)

    if opt.adaptive_move && opt.iter > 2
        update_move!(opt)
    end

    η = 0.5

    bm = -opt.df_obj_k ./ opt.df_vol
    l1 = 0.0
    l2 = 1.2 * maximum(bm)
    x_new = zeros(opt.n)

    while l2 - l1 > 1e-10 * (l2 + 1)
        lm = (l1 + l2) / 2
        be = max.(0.0, bm / lm)
        xt = @. opt.x_min + (opt.x_k - opt.x_min) * be^η
        x_new = @. max(max(min(min(xt, opt.x_k + opt.move), opt.x_max), opt.x_k - opt.move), opt.x_min)
        if (vol - opt.volume_max) + opt.df_vol' * (x_new - opt.x_k) > 0
            l1 = lm
        else
            l2 = lm
        end
    end
    
    opt.x_k = x_new[:]

    # Set areas to the elements
    set_areas(opt)
end


function optimize!(opt::Optimizer)
    error = Inf
    opt.iter = 0
    set_areas(opt)
    opt.df_vol = diff_vol(opt)

    while error > opt.tol && opt.iter < opt.max_iters
        opt.compliance.base.obj_km2 = opt.compliance.base.obj_km1
        opt.compliance.base.obj_km1 = opt.compliance.base.obj_k

        opt.x_km2 = opt.x_km1[:]
        opt.x_km1 = opt.x_k[:]

        update_x!(opt)
        opt.compliance.base.obj_k = obj(opt.compliance)

        update_smooth_parameter!(opt::Optimizer)

        error = ifelse(opt.iter <= opt.min_iters, Inf, norm(opt.x_k - opt.x_km1))

        @info state_to_string(opt, error)

        opt.iter += 1
    end
end

function update_smooth_parameter!(opt::Optimizer)
    # Update smooth parameters
    if typeof(opt.compliance) <: ComplianceSmooth && opt.iter > 2
        update_smooth_parameter!(opt.compliance)
    end
end

function state_to_string(opt::Optimizer, error::Float64)
    s = "Iteration: $(opt.iter)\t $(state_to_string(opt.compliance))\t error: $(ifelse(error == Inf, "-", error))"
    return s
end


# TODO: Create a class Data to store the data of the optimization each iteration. Save in json.
