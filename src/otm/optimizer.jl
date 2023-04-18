include("compliance.jl")

struct Optimizer
    compliance::Compliance
    
    x_min::Float64
    x_max::Float64
    x_init::Float64
    
    x_k::Vector{Float64}
    x_km1::Vector{Float64}
    x_km2::Vector{Float64}

    diff_obj_k::Vector{Float64}
    diff_obj_km1::Vector{Float64}
    diff_obj_km2::Vector{Float64}

    volume_max::Float64

    iter::Int64
    adaptive_move::Bool
    # TODO: Make this initial move as the mean of the initial areas (x_ini)
    move::Vector{Float64}
    tol::Float64
end

diff_vol(optimizer::Optimizer) = [len(el) for el in optimizer.compliance.structure.elements]

function update_move!(optimizer::Optimizer)
    x_k::Vector{Float64} = optimizer.x_k
    x_km1::Vector{Float64} = optimizer.x_km1
    x_km2::Vector{Float64} = optimizer.x_km2
    x_init::Float64 = optimizer.x_init

    terms::Vector{Float64}(undef, length(x_k))
    move_tmp::Vector{Float64} = compliance.move[:]

    if optimizer.iter > 2
        terms = (x_k - x_km1) .* (x_km1 - x_km2)
        for i=eachindex(terms)
            if terms[i] < 0
                move_tmp[i] = 0.9 * compliance.move[i]
            elseif terms[i] > 0
                move_tmp[i] = 1.1 * compliance.move[i]
            end
        end

        compliance.move = max.(1e-4 * x_init, min.(move_tmp, 10 * x_init))
    end
end


function update_x!(optimizer::Optimizer)
    n::Int64 = length(optimizer.compliance.structure.elements)
    diff_obj::Vector{Float64} = diff_obj(optimizer.compliance)
    vol::Float64 = volume(optimizer.compliance.structure)
    diff_vol::Vector{Float64} = diff_vol(optimizer.compliance)
    vol::Float64 = volume(optimizer.compliance.structure)

    if optimizer.adaptive_move
        update_move!(optimizer)
    end

    if optimizer.iter ≤ 2
        η = 0.5
    else
        ratio_diff_obj = @. abs(optimizer.diff_obj_km1 / optimizer.diff_obj_k)
        ratio_x = @. (optimizer.x_km2 + optimizer.tol * x_ini) / (optimizer.x_km1 + optimizer.tol * x_ini)
        a = @. 1 + log(ratio_diff_obj) / log(ratio_x)
        a = max.(min.(map(v -> ifelse(v === NaN, 0, v), a), -0.1), -15)
        η = @. 1 / (1 - a)
    end

    bm::Vector{Float64} = -optimizer.diff_obj_k ./ diff_vol
    be::Vector{Float64}(undef, n)
    l1::Float64 = 0.0
    l2::Float64 = 1.2 * maximum(bm)
    lm::Float64 = 0.0
    x_new::Vector{Float64}(undef, n)

    while l2 - l1 > 1e-6
        lm::Float64 = (l1 + l2) / 2
        be = max.(0.0, bm / lm)
        xt = @. optimizer.x_min + (optimizer.x_k - optimizer.x_min) * be^η
        x_new = @. max(max(min(min(xt, optimizer.x_k + optimizer.move), optimizer.x_max), optimizer.x_k - optimizer.move), optimizer.x_min)
        if (vol - optimizer.volume_max) + diff_vol' * (x_new - optimizer.x_k) > 0
            l1 = lm
        else
            l2 = lm
        end
    end
    
    optimizer.x_k = x_new[:]

    optimizer.iter += 1
end


function optimize!(optimizer::Optimizer)
    error::Float64 = Inf
    optimizer.iter = 0

    while error > optimizer.tol && optimizer.iter < optimizer.max_iters
        optimizer.iter += 1

        optimizer.x_km2 = optimizer.x_km1[:]
        optimizer.x_km1 = optimizer.x_k[:]

        update_x!(optimizer)
        
        error = norm((optimizer.x_k - optimizer.x_km1) ./ (optimizer.x_k + optimizer.tol * optimizer.x_init))
    end
end

# TODO: Create a class Data to store the data of the optimization each iteration. Save in xml.
