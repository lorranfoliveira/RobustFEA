mutable struct Constraint
    rx::Bool
    ry::Bool

    function Constraint(rx::Bool, ry::Bool)
        new(rx, ry)
    end
end

is_free(constraint::Constraint) = constraint.rx == constraint.ry == false
