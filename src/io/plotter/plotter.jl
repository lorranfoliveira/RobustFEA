include("../input/json_reader.jl")

using Plots

struct Plotter
    data::JsonReader
    filename::String

    function Plotter(filename::String)
        new(JsonReader(filename), filename)
    end
end

function plot_compliance(plt::Plotter; plot_min_compliance::Bool=true, plot_max_compliance::Bool=true)  
    p = plot(its_iter(plt.data), its_obj(plt.data), label="Compliance", xlabel="Iteration", ylabel="Compliance")

    if plot_min_compliance
        plot!(p, its_iter(plt.data), its_min_obj(plt.data), label="Min Compliance")
    end

    if plot_max_compliance
        plot!(p, its_iter(plt.data), its_max_obj(plt.data), label="Max Compliance")
    end
    
    display(p)
    sleep(1e6)
end

function plot_structure(plt::Plotter, key::String="output_structure", scale::Float64=1.0, α::Float64=0.0)
    els = elements_data(plt.data, key)
    nodes = nodes_data(plt.data, key)
    areas = sqrt.(areas_data(plt.data, key))
    #areas = areas_data(plt.data, key)
    areas_norm = areas / maximum(areas)

    areas_norm[[ind for ind=eachindex(areas_norm) if areas_norm[ind] <= α]] .= 0.0

    p = plot()

    for i=eachindex(els)
        node1 = nodes[els[i][1]]
        node2 = nodes[els[i][2]]
        x = [node1[1], node2[1], NaN]
        y = [node1[2], node2[2], NaN]
        
        a = areas_norm[i]
        if a > 0.0
            plot!(p, x, y, label="", color=cgrad(:jet, 10, categorical=true)[a], aspect_ratio = :equal, lw = scale*a, ticks = false, showaxis = false)
        end
    end

    savefig(p, "$(replace(plt.filename, ".json" => "")).pdf")
    savefig(p, "$(replace(plt.filename, ".json" => "")).svg")
    display(p)
    sleep(1e6)
end



