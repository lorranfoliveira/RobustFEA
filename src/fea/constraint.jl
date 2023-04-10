"""
Defines a constraint in 2D space.

# Fields
- `dofs::Vector{Bool}`: The degrees of freedom cooresponding to the x and y directions.

# Constructors
- `Constraint(rx::Bool, ry::Bool)`: Creates a new constraint with the given degrees of freedom constraints.
- `Constraint()`: Creates a new constraint with no degrees of freedom.
"""
mutable struct Constraint
    dofs::Vector{Bool}

    function Constraint(rx::Bool, ry::Bool)
        new([rx, ry])
    end

    function Constraint()
        new([false, false])
    end
end

"""
Returns true if the constraint is free.
"""
is_free(constraint::Constraint) = all(constraint.dofs .== false)
