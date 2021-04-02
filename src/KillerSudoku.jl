using Formatting

"""
A single cage for a Killer Sudoku.

Define an area of the grid with a given sum.

# Attributes
- `I::Matrix{Bool}`: A matrix with the same dimensions as the enclosing sudoku grid
                     whose entries are true on the locations belonging to this cage.
- `sum::Int`: The expected sum of the entries in this cage.
- `ω::Vector{Set{Int}}`: A vector with all the possilbe combination of values that
                         add up to the given sum.
"""
struct Cage
    I::Matrix{Bool}
    sum::Int
    ω::Vector{Set{Int}}
    function Cage( I, mSum )
        ω = sum_distribution( mSum, sum(I), size(I)[1] )
        return new( I, mSum, ω )
    end
end


"""Dictionary cache of possible values of entries for a given sum and number of entries."""
Ω = Dict{Tuple{Int,Int},Vector{Set{Int}}}()


"""
    sum_distribution( s::Int, k::Int, inSet::Set{Int} )

Find all combinations of `k` entries with sum `s` with elements from `inSet`.

This is the recursive step for `sum_distribution(s::Int, k::Int, N::Int)`.
"""
function sum_distribution( s::Int, k::Int, inSet::Set{Int} )::Vector{Set{Int}}
    ret = Vector{Set{Int}}()
    if k == 1
        if s in inSet
            push!( ret, Set(s) )
        end
    else
        newInSet = Set(inSet) # make copy
        for e in inSet
            delete!( newInSet, e )
            if e < s
                eω = sum_distribution( s-e, k-1, newInSet )
                for eσ in eω
                    push!( eσ, e )
                end
                append!( ret, eω )
            end
        end
    end
    return ret
end


"""
    sum_distribution( s::Int, k::Int, N::Int )

Find all combinations of `k` entries with sum `s` with entries from 1 to `N`.

# Examples
```julia-repl
julia> Sudoku.sum_distribution(25, 4, 9)
6-element Vector{Set{Int64}}:
 Set([5, 4, 7, 9])
 Set([5, 9, 8, 3])
 Set([4, 6, 7, 8])
 Set([6, 7, 9, 3])
 Set([6, 2, 9, 8])
 Set([7, 9, 8, 1])
 ```
"""
function sum_distribution( s::Int, k::Int, N::Int )::Vector{Set{Int}}
    global Ω
    if !haskey( Ω, (s,k) )
        Ω[(s,k)] = sum_distribution( s, k, Set(1:N) )
    end
    return Ω[(s,k)]
end


"""
    possible_cage_values( m::Cage, B::Grid )

Find all availabe values for a cage `m` given the the grid `B`.
"""
function possible_cage_values( m::Cage, B::Grid )::Set{Int}
    BIs = Set(B[m.I])
    delete!( BIs, 0 ) # 0 is not an actual value, it is just a placeholder for nothing
    possible_values = Set{Int}()
    for σ in m.ω
        if ⊆(BIs, σ)
            union!( possible_values, σ )
        end
    end
    setdiff!( possible_values, BIs )
    return possible_values
end


"""
Define a Killer Sudoku from a vector of Cages.

# Attributes
- `plain::PlainSudoku`: The base sudoku with its boars initially blank.
- `cages::Vector{Cage}`: The vector of cages.
- `cages_idx::Grid`: A grid whose entries are the index of the cage containing the corresponding entry.
"""
struct KillerSudoku <: ASudoku
    plain::PlainSudoku
    cages::Vector{Cage}
    cages_idx::Grid
    function KillerSudoku( cages::Vector{Cage} )
        N         = _get_killer_N( cages )
        plain     = PlainSudoku( zeros( Int, (N,N) ) )
        cages_idx = _get_cages_idx( cages, N )
        return new( plain, cages, cages_idx )
    end
end


"""
    _get_killer_N( cages )

Figure the dimension `N` of the grid from the cages.
"""
function _get_killer_N( cages )::Int
    N_l = [ size(m.I) for m in cages ]
    N   = N_l[1][1]
    n   = round( Int, sqrt(N) )

    if n^2 != N
        error("Grid sides must be square numbers, got $N")
    end
    if N_l[1][2] != N
        error("Invalid cage shape $(N_l[1])")
    end
    if any( [x != (N,N) for x in N_l] )
        error("Cages have different shapes: $(N_l)")
    end
    return N
end


"""
    _get_cages_idx( cages, N )

Compute the `cages_idx` matrix where each entry is the index of the cage that contains it.
"""
function _get_cages_idx( cages, N )::Grid
    cages_idx  = zeros( Int, (N,N) )
    cage_check = zeros( Int, (N,N) )
    for (i,m) in enumerate(cages)
        cages_idx  += i*m.I
        cage_check += m.I
        if any( cage_check .> 1 )
            error("Cage $i overlaps with a previous cage")
        end
    end
    if any( cage_check .!= 1 )
        error("Cages do not cover the whole grid")
    end
    return cages_idx
end


"""
    getgrid( ks::KillerSudoku )

Get the grid for the KillerSudoku.
"""
function getgrid( ks::KillerSudoku )::Grid
    return getgrid( ks.plain )
end


"""
    getN( ks::KillerSudoku )

Get the dimension `N` for the KillerSudoku.
"""
function getN( ks::KillerSudoku )::Int
    return getN( ks.plain )
end


"""
    getn( ks::KillerSudoku )

Get the subdimension `n` for the KillerSudoku.
"""
function getn( ks::KillerSudoku )::Int
    return getn( ks.plain )
end


"""
    issolution( G::Grid, s::PlainSudoku )

Check whether `G` is a solution for the sudoku `s`.
"""
function issolution( G::Grid, ks::KillerSudoku )::Bool
    return issolution( G, ks.plain ) && checkcages( G, ks )
end


"""
    checkcages( G::Grid, ks::KillerSudoku )

Check whether all cages in `G` have the correct sum.
"""
function checkcages( G::Grid, ks::KillerSudoku )::Bool
    for cage in ks.cages
        if sum(G[cage.I]) != cage.sum
            return false
        end
    end
    return true
end


"""
    cage_value_map( v::Int )

Map an `Int` to a character for displaying with `displaygrid`.
"""
function cage_value_map( v::Int )::Char
    if v < 26
        return Char(v+64) # A-Z
    else
        return Char(v+96) # a-z
    end
end


"""
    displaygrid( ks::KillerSudoku )

Display the Killer Sudoku grid as a grid of cages represented by characters
and a legend identifying the required sum for each cage.

# Examples
```julia-repl
julia> displaygrid(ks)
 -------------------------
 | A A B | B C C | D E E |
 | F A G | B C C | D D E |
 | F F G | B H H | H E E |
 -------------------------
 | F I G | B J J | H H K |
 | L I M | N N N | H O K |
 | L M M | P P Q | R O S |
 -------------------------
 | T T M | M M Q | R S S |
 | T U U | V V Q | R W S |
 | T T U | V V Q | Q W W |
 -------------------------

Σ(A) =  6    Σ(B) = 27    Σ(C) = 18    Σ(D) = 14    Σ(E) = 22
Σ(F) = 22    Σ(G) = 21    Σ(H) = 25    Σ(I) = 11    Σ(J) = 17
Σ(K) =  9    Σ(L) =  6    Σ(M) = 38    Σ(N) = 15    Σ(O) = 13
Σ(P) =  7    Σ(Q) = 28    Σ(R) = 12    Σ(S) = 20    Σ(T) = 30
Σ(U) = 12    Σ(V) = 11    Σ(W) = 21
```
"""
function displaygrid( ks::KillerSudoku )
    _displaygrid( ks.cages_idx, ks.plain.N, cage_value_map )
    println()
    for (i, cage) in enumerate(ks.cages)
        printfmt("Σ({1}) = {2:2d}    ", cage_value_map(i), cage.sum )
        if i%5 == 0
            println()
        end
    end
    println()
end


"""
    readsudokufile( ::Type{T}, fname::AbstractString; pyformat=false ) where {T <: KillerSudoku}

Build a Killer Sudoku from a file with the following definition format.

The first line consists of the dimension `N` of the sudoku grid.
Each subsequent line defines a row where the first number is the sum for the cage
and the following pairs of numbers (two numbers separated by a comma) are the
coordinates of the cage.

# Example:
```
N
s1 i11,j11 i12,j12 ... i1k,j1k
s2 i21,j21 i22,j22 ... i2l,j2l
```
"""
function readsudokufile( ::Type{T}, fname::AbstractString; pyformat=false )::T where {T <: KillerSudoku}
    lines  = Iterators.Stateful( readlines(fname) )
    cages  = Vector{Cage}()
    N      = parse( Int, popfirst!(lines) )
    for l in lines
        cage_args = Iterators.Stateful( split(l) )
        I    = zeros( Bool, (N,N) )
        _sum = parse( Int, popfirst!(cage_args) ) # first number is the sum for the cage
        for x in cage_args # each x is a coordinate (i,j) belonging to the cage
            i,j    = parse.(Int,split(x,","))
            if pyformat
                i += 1
                j += 1
            end
            I[i,j] = true
        end
        push!( cages, Cage( I, _sum ) )
    end
    return KillerSudoku( cages )
end


"""
    writesudokufile( fname::AbstractString, ks::KillerSudoku )

Write the Killer Sudoku to file with format as defined in the documentation for [`readsudokufile`](@ref).
"""
function writesudokufile( fname::AbstractString, ks::KillerSudoku )
    open(fname, "w") do io
        write( io, "$(ks.plain.N)")
        for cage in ks.cages
            write( io, "\n$(cage.sum)")
            for ij in findall( cage.I )
                printfmt( io, " {1},{2}", ij[1], ij[2] )
            end
        end
    end
end


"""
    availablevalues( ks::KillerSudoku, B::Grid, N::Int, n::Int, i::Int, j::Int )

Get a vector with the possible values for grid `B` at position `(i,j)`.
"""
function availablevalues( ks::KillerSudoku, B::Grid, N::Int, n::Int, i::Int, j::Int )::Set{Int}
    vals = availablevalues( ks.plain, B, N, n, i, j )
    if !isempty(vals)
        cage_vals = possible_cage_values( ks.cages[ ks.cages_idx[i,j] ], B )
        intersect!( vals, cage_vals )
    end
    return vals
end
