include("src/io/plotter/plotter.jl")

filename = "quad.json"

r = Plotter(filename)
plot_structure(r, "output_structure", 5.0, 0.0)
