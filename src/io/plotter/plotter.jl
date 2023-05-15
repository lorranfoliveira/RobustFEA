include("../input/json_reader.jl")

using Plots

struct Plotter
    data::JsonReader
    filename::String

    function Plotter(filename::String)
        new(JsonReader(filename), filename)
    end
end

function plot_compliance(plt::Plotter)
    p = plot(its_iter(plt.data), its_obj(plt.data), label="Compliance", xlabel="Iteration", ylabel="Compliance")
    display(p)
    sleep(1e6)
end

function plot_structure(plt::Plotter, key::String="output_structure", scale::Float64=1.0)
    els = elements_data(plt.data, key)
    nodes = nodes_data(plt.data, key)
    areas = normalize(areas_data(plt.data, key))
    
    p = plot()

    for i=eachindex(els)
        node1 = nodes[els[i][1]]
        node2 = nodes[els[i][2]]
        x = [node1[1], node2[1], NaN]
        y = [node1[2], node2[2], NaN]

        plot!(p, x, y, label="", color=:black, aspect_ratio = :equal, lw = scale*areas[i], ticks = false, showaxis = false)
    end

    savefig(p, "$(replace(plt.filename, ".json" => "")).pdf")
    display(p)
    sleep(1e6)
end



