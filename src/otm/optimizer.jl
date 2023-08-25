include("compliance/compliance.jl")
include("../io/output/output.jl")

using JSON, Statistics

mutable struct Optimizer
    # manual
    compliance::T where T<:Compliance
    volume_max::Float64
    adaptive_move::Bool
    min_iters::Int64
    max_iters::Int64
    x_min::Float64
    tol::Float64
    γ::Float64

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
    df_obj_km1::Vector{Float64}
    df_obj_km2::Vector{Float64}

    df_vol::Vector{Float64}

    vol::Float64

    output::Output

    filter_tol::Float64
    layout_constraint::Union{Matrix{Int64}, Nothing}
    layout_constraint_divisions::Union{Int}

    function Optimizer(compliance::T; volume_max::Float64=1.0, 
                                      initial_move_parameter::Float64=1.0,
                                      adaptive_move::Bool=true, 
                                      min_iters::Int64=20,
                                      max_iters::Int64=5000, 
                                      x_min::Float64=1e-12, 
                                      tol::Float64=1e-8,
                                      γ::Float64=0.0,
                                      filter_tol::Float64=0.0,
                                      filename::String="output.json",
                                      layout_constraint::Union{Matrix{Int64}, Nothing}=nothing,
                                      layout_constraint_divisions::Union{Int}=0) where T<:Compliance

        els_len = [len(el) for el in compliance.base.structure.elements]
        n = length(compliance.base.structure.elements)

        x_max =  volume_max / minimum(els_len)
        x_init = volume_max / sum(els_len)
        move = initial_move_parameter * fill(x_init, n)
        iter = 1

        x_k = fill(x_init, n)
        x_km1 = zeros(n)
        x_km2 = zeros(n)

        df_obj_k = zeros(n)
        df_obj_km1 = zeros(n)
        df_obj_km2 = zeros(n)

        df_vol_init = zeros(n)

        vol = 0.0
        
        # Create output
        output = Output(filename)
        output.input_structure = OutputStructure(compliance.base.structure)

        new(compliance, 
            volume_max,
            adaptive_move, 
            min_iters,
            max_iters, 
            x_min, 
            tol, 
            γ,
            x_max, 
            x_init, 
            move, 
            iter, 
            n, 
            x_k, 
            x_km1, 
            x_km2, 
            df_obj_k,
            df_obj_km1,
            df_obj_km2,
            df_vol_init,
            vol,
            output,
            filter_tol,
            layout_constraint,
            layout_constraint_divisions)
    end
end

function consider_layout_constraint!(opt::Optimizer)
    if opt.layout_constraint === nothing
        return
    else
        for i=1:size(opt.layout_constraint, 1)
            els = [el for el in opt.layout_constraint[i, :] if el != 0]
            opt.df_obj_k[els] .= sum(opt.df_obj_k[els]) 
            opt.df_vol[els] .= sum(opt.df_vol[els]) 
        end
    end
end

function automatic_layout_constraint!(opt::Optimizer)
    if opt.layout_constraint_divisions > 0
        n = length(opt.x_k) / opt.layout_constraint_divisions
        n = Int64(ceil(ifelse(ceil(n) <= n, n, ceil(n))))

        sort_x_index = zeros(n * opt.layout_constraint_divisions)
        sort_x_index[1:length(opt.x_k)] = sortperm(opt.x_k)
        sort_x_index = reshape(sort_x_index, n, opt.layout_constraint_divisions)'
        
        opt.layout_constraint = sort_x_index

        opt.x_k .= opt.x_init
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
    if opt.iter ≤ 2
        return
    else
        move_tmp = opt.move[:]

        terms = (opt.x_k - opt.x_km1) .* (opt.x_km1 - opt.x_km2)
        for i=eachindex(terms)
            if terms[i] < 0
                move_tmp[i] = 0.7 * opt.move[i]
            elseif terms[i] > 0
                move_tmp[i] = 1.2 * opt.move[i]
            end
        end
    
        opt.move = max.(1e-4 * opt.x_init, min.(move_tmp, 1000 * opt.x_init))
    end
end


function update_x!(opt::Optimizer)
    opt.vol = volume(opt.compliance.base.structure)
    opt.df_obj_k = diff_obj(opt.compliance)
    opt.df_vol = diff_vol(opt)

    consider_layout_constraint!(opt)

    if opt.adaptive_move
        update_move!(opt)
    end

    η = 0.5

    if opt.iter <= Inf
        η = 0.5
    else
        ratio_diff = abs.(opt.df_obj_km1 ./ opt.df_obj_k)
        ratio_x = @. (opt.x_km2 + opt.tol) / (opt.x_km1 + opt.tol)
        a = @. 1 + log(ratio_diff) / log(ratio_x)
        a = max.(min.(map(v -> ifelse(v === NaN, 0, v), a), -2.0), -15)
        η = @. 1 / (1 - a)
    end

    bm = -opt.df_obj_k ./ opt.df_vol
    l1 = 0.0
    l2 = 1.2 * maximum(bm)
    x_new = zeros(opt.n)

    while l2 - l1 > opt.tol * (l2 + 1)
        lm = (l1 + l2) / 2
        be = max.(0.0, bm / lm)
        xt = @. opt.x_min + (opt.x_k - opt.x_min) * be^η
        x_new = @. max(max(min(min(xt, opt.x_k + opt.move), opt.x_max), opt.x_k - opt.move), opt.x_min)
        if (opt.vol - opt.volume_max) + opt.df_vol' * (x_new - opt.x_k) > 0
            l1 = lm
        else
            l2 = lm
        end
    end
    
    x_new = opt.γ * opt.x_k + (1 - opt.γ) * x_new

    opt.x_k = x_new[:]
    set_areas(opt)
end


function optimize!(opt::Optimizer)
    error = Inf
    opt.iter = 0
    set_areas(opt)

    while error > opt.tol && opt.iter < opt.max_iters
        if opt.layout_constraint_divisions ≥ 1 #&& opt.iter % 500 == 0 && opt.iter > 0
            @warn "Applying automatic layout constraint"
            automatic_layout_constraint!(opt)
        end

        opt.compliance.base.obj_km2 = opt.compliance.base.obj_km1
        opt.compliance.base.obj_km1 = opt.compliance.base.obj_k





        #opt.df_obj_km2 = copy(opt.df_obj_km1)
        #opt.df_obj_km1 = copy(opt.df_obj_k)

        #opt.x_km2 = copy(opt.x_km1)
        #opt.x_km1 = copy(opt.x_k)

        #update_x!(opt)









        x_k_tmp = copy(opt.x_k)
        
        update_x!(opt)

        opt.df_obj_km2 = copy(opt.df_obj_km1)
        opt.df_obj_km1 = copy(opt.df_obj_k)
        opt.x_km2 = copy(opt.x_km1)
        opt.x_km1 = copy(x_k_tmp)








        opt.compliance.base.obj_k = obj(opt.compliance)

        #min_max_obj_values = min_max_obj(opt.compliance)
        
        #if opt.output.output_iterations === nothing
        #    opt.output.output_iterations = [OutputIteration(opt.iter, opt.x_k, min_max_obj_values[1], min_max_obj_values[2], opt.compliance.base.obj_k, opt.vol)]
        #else
        #    push!(opt.output.output_iterations, 
        #    OutputIteration(opt.iter, opt.x_k, min_max_obj_values[1], min_max_obj_values[2], opt.compliance.base.obj_k, opt.vol))
        #end

        error = ifelse(opt.iter <= opt.min_iters, Inf, norm((opt.x_k - opt.x_km1) ./ (1 .+ opt.x_km1), Inf))
        #error = ifelse(error === NaN, Inf, error)

        #log_txt = "It: $(opt.iter)  obj: $(obj(opt.compliance))  γ:$(opt.γ)  θc: $(angle(opt))  vol: $(opt.vol)  error: $(ifelse(error == Inf, "-", error))"
        log_txt = "It: $(opt.iter)  obj: $(obj(opt.compliance)) mean_move: $(mean(opt.move)) γ:$(opt.γ)  vol: $(opt.vol)  error: $(ifelse(error == Inf, "-", error))"
        println(log_txt)
        #@info log_txt

        opt.iter += 1
    end

    @info "================== Optimization finished =================="
    @info "File name: $(opt.output.filename)"
    @info "Final compliance: $(obj(opt.compliance))"
    @info "Final volume: $(opt.vol)"
    @info "Final error: $(error)"
    @info "Number of iterations: $(opt.iter)"
    @info "Number of elements: $(length(opt.x_k))"
    @info "Number of nodes: $(length(opt.compliance.base.structure.nodes))"
    @info "Mean move: $(length(mean(opt.move)))"

    if opt.filter_tol > 0.0
        filter!(opt)
    end

    # Results to json
    opt.output.output_structure = OutputStructure(opt.compliance.base.structure)
    save_json(opt.output)
end

function remove_thin_bars(opt::Optimizer)
    @info "================== Removing thin elements =================="

    removed_els = [i for i=eachindex(opt.x_k) if opt.x_k[i] ≈ 0.0]
    elements = copy(opt.compliance.base.structure.elements)

    deleteat!(elements, removed_els)
    deleteat!(opt.x_k, removed_els)
    deleteat!(opt.x_km1, removed_els)
    deleteat!(opt.x_km2, removed_els)
    deleteat!(opt.df_obj_k, removed_els)
    deleteat!(opt.df_obj_km1, removed_els)
    deleteat!(opt.df_obj_km2, removed_els)
    deleteat!(opt.move, removed_els)

    new_nodes::Vector{Node} = []
    nd_id = 1
    for (el_id, el) in enumerate(elements)
        el.id = el_id
        for node in el.nodes
            if node ∉ new_nodes
                node.id = nd_id 
                nd_id += 1
                push!(new_nodes, node)
            end
        end
    end

    @info "Elements removed: $(length(removed_els))"
    @info "Nodes removed: $(length(opt.compliance.base.structure.nodes) - length(new_nodes))"

    opt.compliance.base.structure = Structure(new_nodes, elements)
    set_areas(opt)
end

function filter!(opt::Optimizer; ρ::Float64=1e-4)
    @info "================== Applying filter =================="
    x_old = opt.x_k[:]
    c_old = opt.compliance.base.obj_k

    α₀ = 0.0
    α₁ = 1.0
    α_old = 0.0
    Δα = 1.0

    Δc = Inf

    if typeof(opt.compliance) <: ComplianceSmooth
        f = H(compliance.base) * compliance.base.eig_vecs[:,end]
    else
        f = forces(opt.compliance.base.structure, include_restricted=true)
    end

    i = 1
    while Δα > 1e-4 && i < 100
        α = (α₀ + α₁) / 2
        norm_x = opt.x_k / maximum(opt.x_k)
        opt.x_k[[ind for ind=eachindex(norm_x) if norm_x[ind] <= α]] .= 0.0
        set_areas(opt)

        disp = K(opt.compliance.base.structure, use_tikhonov=true) \ f
        r = norm(K(opt.compliance.base.structure, use_tikhonov=false)*disp - f) / norm(f)

        c = opt.compliance.base.obj_k = obj(opt.compliance, recalculate_eigenvals=true)

        Δc = abs(c - c_old) / c_old

        if r ≤ ρ && Δc < opt.filter_tol
            x_old = opt.x_k[:]
            Δα = abs(α_old - α)
            α_old = α
            α₀ = α
            c_old = c
        else
            opt.x_k = x_old[:]
            α₁ = α
        end


        @info "i: $i \tα: $α \tc: $c \tr: $r \tΔc: $Δc \tΔα: $Δα"

        i += 1
    end

    remove_thin_bars(opt)    

    @info "==============================================================="
end

function angle(opt::Optimizer)
    forces = H(opt.compliance.base) * opt.compliance.base.eig_vecs[:,end]
    fx, fy = [f for f in forces if abs(f) > 0.0][1:2]

    return atand(fy, fx)
end
