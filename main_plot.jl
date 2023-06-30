include("src/io/plotter/plotter.jl")

filename = "hook_ref.json"

r = Plotter(filename)
plot_structure(r, "output_structure", 5.0, 1e-4)
