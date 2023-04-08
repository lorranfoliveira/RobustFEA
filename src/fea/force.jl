mutable struct Force
    fx::Float64
    fy::Float64

    function Force(fx::Float64, fy::Float64)
        new(fx, fy)
    end

    function Force()
        new(0.0, 0.0)
    end

    function Force(force::Float64, angle::Float64)
        new(force * cos(angle), force * sin(angle))
    end
end

function resultant(force::Force)
    return sqrt(force.fx * force.fx + force.fy * force.fy)
end

function angle(force::Force)
    return atan(force.fy, force.fx)
end
