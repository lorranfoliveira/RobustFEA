include("json_reader.jl")

r = JsonReader("output.json")
println(its_vol(r))
