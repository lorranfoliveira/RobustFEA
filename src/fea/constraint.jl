export Constraint, is_free

mutable struct Constraint
    dofs::Vector{Bool}

    function Constraint(rx::Bool, ry::Bool)
        new([rx, ry])
    end

    function Constraint()
        new([false, false])
    end
end

is_free(constraint::Constraint) = all(constraint.dofs .== false)
