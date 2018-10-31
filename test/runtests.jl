# import BlockRegistration
using CenterIndexedArrays, Test, Random

CenterIndexedArray(Float32, 3, 5)
@test_throws ErrorException CenterIndexedArray(Float32, 4, 5)

dat = rand(3,5)
A = CenterIndexedArray(dat)
@test size(A) == size(dat)
@test length(A) == length(dat)
@test ndims(A) == 2
@test eltype(A) == eltype(dat)

@test A[0,0] == dat[2,3]
k = 0
for j = -2:2, i = -1:1
    global k += 1
    @test A[i,j] == dat[k]
end
@test_throws BoundsError A[3,5]
@test A[:,-1:1].data == dat[:,2:4]
@test A[-1:1,:].data == dat[:,:]
@test_throws ErrorException A[:,-2:0]
k = 0
for j = -2:2, i = -1:1
    A[i,j] = (global k+=1)
end
@test dat == reshape(1:15, 3, 5)
@test_throws BoundsError A[3,5] = 15

rand!(dat)
iall = (-1:1).*ones(Int, 5)'
jall = ones(Int,3).*(-2:2)'
k = 0
for I in eachindex(A)
    global k += 1
    @test I[1] == iall[k]
    @test I[2] == jall[k]
end

io = IOBuffer()
show(io, MIME("text/plain"), A)
str = String(take!(io))
@test isempty(something(findfirst(str, "undef"), 0:-1))

# Iteration
for (a,d) in zip(A, dat)
    @test a == d
end

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
