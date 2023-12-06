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
    poisson::Float64
    elastic_matrix::Matrix{Float64}

    function Material(id::Int64, young::Float64=1, poisson::Float64=0.3, elastic_matrix::Matrix{Float64}=zeros(3, 3))
        if id <= 0
            error("Material id must be positive")
        end

        if young <= 0
            error("Young's modulus must be positive")
        end

        if poisson < 0 || poisson > 0.5
            error("Poisson's ratio must be between 0 and 0.5")
        end
        
        new(id, young, poisson, elastic_matrix)
    end

    function isotropic_elastic_matrix(self::Material)
        E = self.young
        ν = self.poisson
        λ = ν * E / ((1 + ν) * (1 - 2 * ν))
        μ = E / (2 * (1 + ν))
        return [λ + 2μ  λ       0;
                λ       λ + 2μ  0;
                0       0       μ]
    end
end