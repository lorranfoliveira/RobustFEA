using LinearAlgebra

export Force, resultant, angle

mutable struct Force
    forces::Vector{Float64}

    function Force(fx::Float64, fy::Float64)
        new([fx, fy])
    end

    function Force()
        new([0.0, 0.0])
    end
end

function resultant(force::Force)
    return norm(force.forces)
end

function angle(force::Force)
    return atan(force.forces[2], force.forces[1])
end
