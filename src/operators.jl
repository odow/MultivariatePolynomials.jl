# We reverse the order of comparisons here so that the result
# of x < y is equal to the result of Monomial(x) < Monomial(y)
@pure isless(v1::AbstractVariable, v2::AbstractVariable) = name(v1) > name(v2)
isless(m1::AbstractTermLike, m2::AbstractTermLike) = isless(promote(m1, m2)...)

function isless(t1::AbstractTerm, t2::AbstractTerm)
    if monomial(t1) < monomial(t2)
        true
    elseif monomial(t1) == monomial(t2)
        coefficient(t1) < coefficient(t2)
    else
        false
    end
end

for op in [:+, :-, :*, :(==)]
    @eval $op(p1::APL, p2::APL) = $op(promote(p1, p2)...)
end
isapprox(p1::APL, p2::APL; kwargs...) = isapprox(promote(p1, p2)...; kwargs...)

# @eval $op(p::APL, α) = $op(promote(p, α)...) would be less efficient
for (op, fun) in [(:+, :plusconstant), (:-, :minusconstant), (:*, :multconstant), (:(==), :eqconstant)]
    @eval $op(p::APL, α) = $fun(p, α)
    @eval $op(α, p::APL) = $fun(α, p)
end
isapprox(p::APL, α; kwargs...) = isapproxconstant(promote(p, α)...; kwargs...)
isapprox(α, p::APL; kwargs...) = isapproxconstant(promote(p, α)...; kwargs...)

(-)(m::AbstractMonomialLike) = (-1) * m
(-)(t::AbstractTermLike) = (-coefficient(t)) * monomial(t)

# Avoid adding a zero constant that might artificially increase the Newton polytope
# Need to add polynomial conversion for type stability
plusconstant(p::APL, α) = iszero(α) ? polynomial(p) : p + constantterm(α, p)
plusconstant(α, p::APL) = plusconstant(p, α)
minusconstant(p::APL, α) = iszero(α) ? polynomial(p) : p - constantterm(α, p)
minusconstant(α, p::APL) = iszero(α) ? polynomial(-p) : constantterm(α, p) - p

(+)(x::APL, y::MatPolynomial) = x + polynomial(y)
(+)(x::MatPolynomial, y::APL) = polynomial(x) + y
(+)(x::MatPolynomial, y::MatPolynomial) = polynomial(x) + polynomial(y)
(-)(x::APL, y::MatPolynomial) = x - polynomial(y)
(-)(x::MatPolynomial, y::APL) = polynomial(x) - y
(-)(x::MatPolynomial, y::MatPolynomial) = polynomial(x) - polynomial(y)

# Coefficients and variables commute
multconstant(α, v::AbstractVariable) = multconstant(α, monomial(v)) # TODO linear term
multconstant(m::AbstractMonomialLike, α) = multconstant(α, m)
multconstant(α, p::AbstractPolynomialLike) = multconstant(α, polynomial(p))
multconstant(p::AbstractPolynomialLike, α) = multconstant(polynomial(p), α)

multconstant(α, t::AbstractTermLike)    = (α*coefficient(t)) * monomial(t)
multconstant(t::AbstractTermLike, α)    = (coefficient(t)*α) * monomial(t)

(*)(m1::AbstractMonomialLike, m2::AbstractMonomialLike) = *(promote(m1, m2)...)
#(*)(m1::AbstractMonomialLike, m2::AbstractMonomialLike) = *(monomial(m1), monomial(m2))

(*)(m::AbstractMonomialLike, t::AbstractTermLike) = coefficient(t) * (m * monomial(t))
(*)(t::AbstractTermLike, m::AbstractMonomialLike) = coefficient(t) * (monomial(t) * m)
(*)(t1::AbstractTermLike, t2::AbstractTermLike) = (coefficient(t1) * coefficient(t2)) * (monomial(t1) * monomial(t2))

(*)(t::AbstractTermLike, p::APL) = polynomial(map(te -> t * te, terms(p)))
(*)(p::APL, t::AbstractTermLike) = polynomial(map(te -> te * t, terms(p)))

Base.transpose(v::AbstractVariable) = v
Base.transpose(m::AbstractMonomial) = m
Base.transpose(t::T) where {T <: AbstractTerm} = transpose(coefficient(t)) * monomial(t)
Base.transpose(p::AbstractPolynomialLike) = polynomial(map(transpose, terms(p)))

Base.dot(p1::AbstractPolynomialLike, p2::AbstractPolynomialLike) = (@show p1; p1' * p2)
Base.dot(x, p::AbstractPolynomialLike) = (@show p; x' * p)
Base.dot(p::AbstractPolynomialLike, x) = (@show p; p' * x)
