using Formatting

"""
A single mask for a Killer Sudoku.

Define an area of the board with a given sum.

# Attributes
- `I::Matrix{Bool}`: A matrix with the same dimensions as the enclosing sudoku board
                     whose entries are true on the locations belonging to this mask.
- `sum::Int`: The expected sum of the entries in this mask.
- `ω::Vector{Set{Int}}`: A vector with all the possilbe combination of values that
                         add up to the given sum.
"""
struct KillerMask
    I::Matrix{Bool}
    sum::Int
    ω::Vector{Set{Int}}
    function KillerMask( I, mSum )
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
    possible_mask_values( m::KillerMask, B::BoardT )

Find all availabe values for a mask `m` given the the board `B`.
"""
function possible_mask_values( m::KillerMask, B::BoardT )::Set{Int}
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
Define a Killer Sudoku from a vector of KillerMasks `masks`.

# Attributes
- `plain::PlainSudoku`: The base sudoku with its boars initially blank.
- `masks::Vector{KillerMask}`: The vector of masks.
- `masks_idx::BoardT`: A board whose entries are the index of the mask containing the corresponding entry.
"""
struct KillerSudoku <: ASudoku
    plain::PlainSudoku
    masks::Vector{KillerMask}
    masks_idx::BoardT
    function KillerSudoku( masks::Vector{KillerMask} )
        N         = _get_killer_N( masks )
        plain     = PlainSudoku( zeros( Int, (N,N) ) )
        masks_idx = _get_masks_idx( masks, N )
        return new( plain, masks, masks_idx )
    end
end


"""
    _get_killer_N( masks )

Figure the dimension `N` of the board from the masks.
"""
function _get_killer_N( masks )::Int
    N_l = [ size(m.I) for m in masks ]
    N   = N_l[1][1]
    n   = round( Int, sqrt(N) )

    if n^2 != N
        error("Board sides must be square numbers, got $N")
    end
    if N_l[1][2] != N
        error("Invalid mask shape $(N_l[1])")
    end
    if any( [x != (N,N) for x in N_l] )
        error("Masks have different shapes: $(N_l)")
    end
    return N
end


"""
    _get_masks_idx( masks, N )

Compute the `masks_idx` matrix where each entry is the index of the mask that contains it.
"""
function _get_masks_idx( masks, N )::BoardT
    masks_idx  = zeros( Int, (N,N) )
    mask_check = zeros( Int, (N,N) )
    for (i,m) in enumerate(masks)
        masks_idx  += i*m.I
        mask_check += m.I
        if any( mask_check .> 1 )
            error("Mask $i overlaps with a previous mask")
        end
    end
    if any( mask_check .!= 1 )
        error("Masks do not cover the whole board")
    end
    return masks_idx
end


"""
    getboard( ks::KillerSudoku )

Get the board for the KillerSudoku.
"""
function getboard( ks::KillerSudoku )::BoardT
    return getboard( ks.plain )
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
    mask_value_map( v::Int )

Map an `Int` to a character for displaying with `displayboard`.
"""
function mask_value_map( v::Int )::Char
    if v < 26
        return Char(v+64) # A-Z
    else
        return Char(v+96) # a-z
    end
end


"""
    displayboard( ks::KillerSudoku )

Display the Killer Sudoku board as a board of masks represented by characters
and a legend identifying the required sum for each mask.

# Examples
```julia-repl
julia> displayboard(ks)
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
function displayboard( ks::KillerSudoku )
    _displayboard( ks.masks_idx, ks.plain.N, mask_value_map )
    println()
    for (i, mask) in enumerate(ks.masks)
        printfmt("Σ({1}) = {2:2d}    ", mask_value_map(i), mask.sum )
        if i%5 == 0
            println()
        end
    end
    println()
end


"""
    readsudokufile( ::Type{T}, fname::AbstractString; pyformat=false ) where {T <: KillerSudoku}

Build a Killer Sudoku from a file with the following definition format.

The first line consists of the dimension `N` of the sudoku board.
Each subsequent line defines a row where the first number is the sum for the mask
and the following pairs of numbers (two numbers separated by a comma) are the
coordinates of the mask.

# Example:
```
N
s1 i11,j11 i12,j12 ... i1k,j1k
s2 i21,j21 i22,j22 ... i2l,j2l
```
"""
function readsudokufile( ::Type{T}, fname::AbstractString; pyformat=false )::KillerSudoku where {T <: KillerSudoku}
    lines  = Iterators.Stateful( readlines(fname) )
    masks  = Vector{KillerMask}()
    N      = parse( Int, popfirst!(lines) )
    for l in lines
        mask_args = Iterators.Stateful( split(l) )
        I    = zeros( Bool, (N,N) )
        _sum = parse( Int, popfirst!(mask_args) ) # first number is the sum for the mask
        for x in mask_args # each x is a coordinate (i,j) belonging to the mask
            i,j    = parse.(Int,split(x,","))
            if pyformat
                i += 1
                j += 1
            end
            I[i,j] = true
        end
        push!( masks, KillerMask( I, _sum ) )
    end
    return KillerSudoku( masks )
end


"""
    writesudokufile( fname::AbstractString, ks::KillerSudoku )

Write the Killer Sudoku to file with format as defined in the documentation for [`readsudokufile`](@ref).
"""
function writesudokufile( fname::AbstractString, ks::KillerSudoku )
    open(fname, "w") do io
        write( io, "$(ks.plain.N)")
        for mask in ks.masks
            write( io, "\n$(mask.sum)")
            for ij in findall( mask.I )
                printfmt( io, " {1},{2}", ij[1], ij[2] )
            end
        end
    end
end


"""
    availablevalues( ks::KillerSudoku, B::BoardT, N::Int, n::Int, i::Int, j::Int )

Get a vector with the possible values for board `B` at position `(i,j)`.
"""
function availablevalues( ks::KillerSudoku, B::BoardT, N::Int, n::Int, i::Int, j::Int )::Set{Int}
    vals = availablevalues( ks.plain, B, N, n, i, j )
    if !isempty(vals)
        mask_vals = possible_mask_values( ks.masks[ ks.masks_idx[i,j] ], B )
        intersect!( vals, mask_vals )
    end
    return vals
end
