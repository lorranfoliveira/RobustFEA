mutable struct Point
    x::Float64
    y::Float64

    function Point(x::Float64, y::Float64)
        new(x, y)
    end

    function Point()
        new(0.0, 0.0)
    end
end

Δx(p1::Point, p2::Point) = p2.x - p1.x 

Δy(p1::Point, p2::Point) = p2.y - p1.y

function distance(p1::Point, p2::Point)
    dx = Δx(p1, p2)
    dy = Δy(p1, p2)
    return sqrt(dx * dx + dy * dy)
end
