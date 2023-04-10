"""
Defines a material for use in the finite element method.

# Fields
- `id::Int64`: The material id.
- `young::Float64`: The Young's modulus of the material.

# Constructors
- `Material(id::Int64, young::Float64)`: Creates a new material with the given id and Young's modulus.

# Errors
- `Material id must be positive`: The material id must be positive.
- `Young's modulus must be positive`: The Young's modulus must be positive.
"""
struct Material
    id::Int64
    young::Float64

    function Material(id::Int64, young::Float64)
        if id <= 0
            error("Material id must be positive")
        end

        if young <= 0
            error("Young's modulus must be positive")
        end
        
        new(id, young)
    end
end