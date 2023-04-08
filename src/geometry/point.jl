export Point, distance, Δcoords

mutable struct Point
    coords::Vector{Float64}

    function Point(x::Float64, y::Float64)
        new([x, y])
    end
    function Point()
        new([0.0, 0.0])
    end
end

Δcoords(p1::Point, p2::Point) = p2.coords - p1.coords 

function distance(p1::Point, p2::Point)
    d_coords = Δcoords(p1, p2)
    return sqrt(sum(d_coords .* d_coords))
end
