include("point.jl")

"""
Defines a segment in 2D space.

# Fields
- `p1::Point`: The first point of the segment.
- `p2::Point`: The second point of the segment.

# Constructors
- `Segment(p1::Point, p2::Point)`: Creates a new segment with the given points.
- `Segment(x1::Float64, y1::Float64, x2::Float64, y2::Float64)`: Creates a new segment with the given coordinates.
"""
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

"""
Returns the length of a segment.
"""
length(segment::Segment)::Float64 = distance(segment.p1, segment.p2)

"""
Returns the cosine of the angle between the x-axis and the segment.
"""
cos(segment::Segment)::Float64 = (segment.p2.coords[1] - segment.p1.coords[1]) / length(segment)

"""
Returns the sine of the angle between the x-axis and the segment.
"""
sin(segment::Segment)::Float64 = (segment.p2.coords[2] - segment.p1.coords[2]) / length(segment)

"""
Returns the angle between the x-axis and the segment.
"""
angle(segment::Segment)::Float64 = atan(sin(segment), cos(segment))
