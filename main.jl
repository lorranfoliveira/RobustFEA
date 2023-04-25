include("src/io/plotter/plotter.jl")

r = Plotter("output.json")
plot_optimized_structure(r, 10.0)
