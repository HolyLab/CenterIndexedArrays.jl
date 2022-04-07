# For the ambiguity test, we need to check the dependencies first
using Interpolations, OffsetArrays
using Test, Random
using OffsetArrays: IdentityUnitRange

if !isdefined(@__MODULE__, :ambs)
    const ambs = detect_ambiguities(Base, Interpolations, OffsetArrays)
end

using CenterIndexedArrays
using CenterIndexedArrays: SymRange

@testset "Ambiguities" begin
    ambscia = detect_ambiguities(Base, Interpolations, OffsetArrays, CenterIndexedArrays)
    VERSION >= v"1.1" && @test isempty(setdiff(ambscia, ambs))
end

@testset "SymRange" begin
    r = SymRange(3)
    @test first(r) == -3
    @test last(r)  ==  3
    @test axes(r) == (r,)
    @test axes(r, 1) == r
    @test size(r) == (7,)

    items = []
    for i in r
        push!(items, i)
    end
    @test items == -3:3

    @test r[-3] == -3
    @test r[3] == 3
    @test_throws BoundsError r[-4]
    @test_throws BoundsError r[4]
    s = SymRange(2)
    @test r[s] == s
    @test r[1:2] == 1:2
    @test intersect(r, s) == s

    @test convert(SymRange, -2:2) === SymRange(2)
    @test_throws ErrorException convert(SymRange, -2:1)
    # The following seems a bit wrong
    @test @inferred(promote(1:2, SymRange(2))) === (1:2, -2:2)

    io = IOBuffer()
    print(io, r)
    @test String(take!(io)) == "SymRange(3)"
end

@testset "Uninitialized" begin
    @test isa(CenterIndexedArray{Float32,2}(undef, 3, 5), CenterIndexedArray)
    @test isa(CenterIndexedArray{Float32,2}(undef, (3, 5)), CenterIndexedArray)
    @test isa(CenterIndexedArray{Float32}(undef, 3, 5), CenterIndexedArray)
    @test isa(CenterIndexedArray{Float32}(undef, (3, 5)), CenterIndexedArray)
    @test_throws ErrorException CenterIndexedArray{Float32}(undef, 4, 5)
end

@testset "Construction & traits" begin
    dat = rand(3,5)
    A = CenterIndexedArray(dat)
    @test size(A) == size(dat)
    @test axes(A) === (SymRange(1), SymRange(2))
    @test length(A) == length(dat)
    @test ndims(A) == 2
    @test eltype(A) == eltype(dat)
end

@testset "Indexing & iteration" begin
    dat = rand(3,5)
    A = CenterIndexedArray(dat)
    @test A[0,0] == dat[2,3]
    k = 0
    for j = -2:2, i = -1:1
        @test @inferred(A[i,j]) == dat[k+=1]
    end
    @test_throws BoundsError A[3,5]
    @test @inferred(A[:,:]) == A
    @test @inferred(A[:,SymRange(1)]) == CenterIndexedArray(dat[:,2:4])
    @test @inferred(A[SymRange(1),:]) == A
    @test @inferred(A[:,-2:0]) == OffsetArray(dat[:,1:3], -1:1, 1:3)  # axes-of-the-axes
    @test @inferred(A[:,IdentityUnitRange(-2:0)]) == OffsetArray(dat[:,1:3], -1:1, -2:0)
    k = 0
    for j = -2:2, i = -1:1
        A[i,j] = (k+=1)
    end
    @test dat == reshape(1:15, 3, 5)
    @test_throws BoundsError A[3,5] = 15

    rand!(dat)
    iall = (-1:1).*ones(Int, 5)'
    jall = ones(Int,3).*(-2:2)'
    k = 0
    for I in eachindex(A)
        k += 1
        @test I[1] == iall[k]
        @test I[2] == jall[k]
    end

    # Iteration
    for (a, d) in zip(A, dat)
        @test a == d
    end
end

@testset "Display" begin
    A = CenterIndexedArray(reshape(1:15, 3, 5))
    io = IOBuffer()
    show(io, MIME("text/plain"), A)
    str = String(take!(io))
    @test endswith(str, "CenterIndexedArray(reshape(::UnitRange{$Int}, 3, 5)) with eltype $Int with indices SymRange(1)×SymRange(2):\n 1  4  7  10  13\n 2  5  8  11  14\n 3  6  9  12  15")
end

@testset "Operations" begin
    dat = rand(3,5)
    A = CenterIndexedArray(dat)
    # Standard julia operations
    B = copy(A)

    @test B.data == dat
    @test B == A
    @test isequal(B, A)

    @test vec(A) == vec(dat)

    @test minimum(A) == minimum(dat)
    @test maximum(A) == maximum(dat)
    @test minimum(A,dims=1) == CenterIndexedArray(minimum(dat,dims=1))
    @test maximum(A,dims=2) == CenterIndexedArray(maximum(dat,dims=2))

    amin, iamin = findmin(A)
    dmin, idmin = findmin(dat)
    @test amin == dmin
    @test A[iamin] == amin
    @test amin == dat[idmin]

    amax, iamax = findmax(A)
    dmax, idmax = findmax(dat)
    @test amax == dmax
    @test A[iamax] == amax
    @test amax == dat[idmax]

    fill!(A, 2)
    @test all(x->x==2, A)

    ii, jj = begin
        II = findall(!iszero, A)
        (getindex.(II, 1), getindex.(II, 2))
    end
    iall = (-1:1).*ones(Int, 5)'
    jall = ones(Int,3).*(-2:2)'
    @test vec(ii) == vec(iall)
    @test vec(jj) == vec(jall)

    rand!(dat)

    # @test cat(1, A, dat) == cat(1, dat, dat)
    # @test cat(2, A, dat) == cat(2, dat, dat)

    @test permutedims(A, (2,1)) == CenterIndexedArray(permutedims(dat, (2,1)))
    # @test ipermutedims(A, (2,1)) == CenterIndexedArray(ipermutedims(dat, (2,1)))

    @test cumsum(A, dims=1) == CenterIndexedArray(cumsum(dat, dims=1))
    @test cumsum(A, dims=2) == CenterIndexedArray(cumsum(dat, dims=2))

    @test mapslices(v->sort(v), A, dims=1) == CenterIndexedArray(mapslices(v->sort(v), dat, dims=1))
    @test mapslices(v->sort(v), A, dims=2) == CenterIndexedArray(mapslices(v->sort(v), dat, dims=2))

    @test reverse(A, dims=1) == CenterIndexedArray(reverse(dat, dims=1))
    @test reverse(A, dims=2) == CenterIndexedArray(reverse(dat, dims=2))

    @test A .+ 1 == CenterIndexedArray(dat .+ 1)
    @test 2*A == CenterIndexedArray(2*dat)
    @test A+A == CenterIndexedArray(dat+dat)
    @test isa(A .+ 1, CenterIndexedArray)
end

@testset "Interpolations integration" begin
    y = 1:3
    yc = CenterIndexedArray(y)
    itp = interpolate(yc, BSpline(Linear()))
    @test itp(0.2) ≈ 2.2
    y = [4.0, 1.0, 0.0, 1.0, 4.0]
    yc = CenterIndexedArray(y)
    itp = interpolate!(yc, BSpline(Quadratic(InPlaceQ(OnCell()))))
    @test itp(0.2) ≈ 0.2^2
end
