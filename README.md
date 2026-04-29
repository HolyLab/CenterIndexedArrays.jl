# CenterIndexedArrays

[![CI](https://github.com/HolyLab/CenterIndexedArrays.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/HolyLab/CenterIndexedArrays.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/HolyLab/CenterIndexedArrays.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/HolyLab/CenterIndexedArrays.jl)
[![version](https://juliahub.com/docs/General/CenterIndexedArrays/stable/version.svg)](https://juliahub.com/ui/Packages/General/CenterIndexedArrays)
[![Aqua QA](https://juliatesting.github.io/Aqua.jl/dev/assets/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

A `CenterIndexedArray` is an array indexed symmetrically around its midpoint: the center
element is always at index `(0, 0, …)`, and along each dimension of size `2n+1` the valid
indices run from `-n` to `n`. All dimension sizes must be odd.

A common use case is image registration, where the mismatch between two images is stored as
a function of their relative displacement — the center of that array is naturally the
zero-displacement case.

## Installation

```julia
using Pkg
Pkg.add("CenterIndexedArrays")
```

## Basic usage

```jldoctest
julia> using CenterIndexedArrays

julia> A = CenterIndexedArray(reshape(1:15, 3, 5))
3×5 CenterIndexedArray(reshape(::UnitRange{Int64}, 3, 5)) with eltype Int64 with indices SymRange(1)×SymRange(2):
 1  4  7  10  13
 2  5  8  11  14
 3  6  9  12  15

julia> A[0, 0]   # center element
8

julia> A[0, -1]  # one step left of center
5

julia> A[-1, 2]  # one step above, two steps right
13
```

You can also allocate an uninitialized array:

```jldoctest
julia> using CenterIndexedArrays

julia> B = CenterIndexedArray{Float64}(undef, 3, 5);

julia> axes(B)
(SymRange(1), SymRange(2))

julia> size(B)
(3, 5)
```

## SymRange axes

The axes of a `CenterIndexedArray` are `SymRange` values — unit ranges symmetric around
zero. `SymRange(n)` covers `-n:n` and has length `2n+1`.

```jldoctest
julia> using CenterIndexedArrays: SymRange

julia> r = SymRange(3)
SymRange(3)

julia> length(r)
7

julia> first(r), last(r)
(-3, 3)

julia> r[-3], r[3]
(-3, 3)
```

## Interpolation

Wrapping an `Interpolations.jl` interpolation object enables fractional (sub-integer)
indexing, which is useful when computing cross-correlations at non-integer offsets.

```jldoctest
julia> using CenterIndexedArrays, Interpolations

julia> dat = collect(reshape(1.0:25.0, 5, 5));

julia> itp = interpolate(dat, BSpline(Linear()));

julia> A = CenterIndexedArray(itp);

julia> A[0, 0]       # center, equivalent to dat[3, 3]
13.0

julia> A[0.5, 0.0]   # fractional index; linearly interpolated
13.5
```
