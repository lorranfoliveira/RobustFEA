include("../point/point.jl")

mutable struct Segment
    p1::Point
    p2::Point

    function Segment(p1::Point, p2::Point)
        new(p1, p2)
    end

    function Segment(x1::Float64, y1::Float64, x2::Float64, y2::Float64)
        new(Point(x1, y1), Point(x2, y2))
    end
end

length(segment::Segment) = distance(segment.p1, segment.p2)

cos(segment::Segment) = (segment.p2.x - segment.p1.x) / length(segment)

sin(segment::Segment) = (segment.p2.y - segment.p1.y) / length(segment)

angle(segment::Segment) = atan(sin(segment), cos(segment))
