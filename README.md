# CenterIndexedArrays

[![Build Status](https://travis-ci.org/HolyLab/CenterIndexedArrays.jl.svg?branch=master)](https://travis-ci.org/HolyLab/CenterIndexedArrays.jl)

A CenterIndexedArray is an array indexed symmetrically around its midpoint.
Here's a quick demo:

```julia
julia> A = CenterIndexedArray(reshape(1:15, 3, 5))
3×5 CenterIndexedArray(reshape(::UnitRange{Int64}, 3, 5)) with eltype Int64 with indices SymRange(1)×SymRange(2):
 1  4  7  10  13
 2  5  8  11  14
 3  6  9  12  15

julia> A[0, 0]   # the center point
8

julia> A[0, -1]
5
```

An example application is in image registration, to encode the mismatch between two images as you displace them relative to one another.

The axes, `SymRange`, are symmetric ranges. They too are indexed symmetrically around 0:

```julia
julia> r = CenterIndexedArrays.SymRange(3)
SymRange(3)

julia> length(r)
7

julia> r[7]
ERROR: BoundsError: attempt to access 7-element SymRange with indices SymRange(3) at index [7]
Stacktrace:
 [1] throw_boundserror(::SymRange, ::Int64) at ./abstractarray.jl:538
 [2] getindex(::SymRange, ::Int64) at /home/tim/.julia/dev/CenterIndexedArrays/src/symrange.jl:28
 [3] top-level scope at none:0

julia> r[-3]
-3

julia> r[3]
3
```
