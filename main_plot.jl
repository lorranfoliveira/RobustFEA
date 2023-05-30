include("src/io/plotter/plotter.jl")

filename = "beam.json"
r = Plotter(filename)
plot_compliance(r)
