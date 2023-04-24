using JSON, Plots

struct Plotter
    filename::String
    json_data::Dict

    function Plotter(filename::String)
        new(filename, JSON.parse(read(filename, String)))
    end
end

function plot_optimized_structure(plt::Plotter)
    areas = normalize(plt.json_data["iterations"][end]["x"])
    els = plt.json_data["elements"]

    for el in els
        x[el["id"]] = el["x"]
    end


    p = plot()
    # Plotagem dos elementos.
    x = []
    y = []
    for el in otimizador.estrutura.elementos
        
        push!(x, [NaN, el["nodes"][1]["positions"][1]]...)
        push!(y, [NaN, el.no₁.y, el.no₂.y]...)
    end
    plot!(
        p,
        x,
        y,
        #xlim=xlims,
        #ylim=ylims,
        label = "",
        lw = area * 4,
        color = ifelse(tens[i] < 0, :red, :blue),
        aspect_ratio = :equal,
        ticks = false,
        showaxis = false
    )

    plotar_forcas_apoios!(p, otimizador, true)

    #plot!(size=(1000,700))
    #png("$arquivo.png")

    #display(p)
    #sleep(10000)
    savefig("$arquivo.svg")
    #return p

end