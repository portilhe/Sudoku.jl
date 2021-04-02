"""
Type alias for the grid of a sudoku, which is always a square matrix.
"""
Grid  = Matrix{Int}


"""
Define a plain Sudoku from a given borad state.

# Attributes
- `B::Grid`: The grid.
- `N::Int`: The dimension of the side of the grid.
- `n:Int`: The subdimension of the side of the grid, `sqrt(N)`.
"""
struct PlainSudoku <: ASudoku
    G::Grid
    N::Int
    n::Int
    function PlainSudoku( G::Grid )
        N, _N = size(G)
        if N != _N
            error( "grid is not square" )
        end
        n = Int(round(sqrt(N)))
        return new( G, N, n )
    end
end


"""
    getgrid( s::PlainSudoku )

Get the grid for the Sudoku.
"""
function getgrid( s::PlainSudoku )::Grid
    return s.G
end


"""
    getN( s::PlainSudoku )

Get the dimension `N` for the Sudoku.
"""
function getN( s::PlainSudoku )::Int
    return s.N
end


"""
    getn( s::PlainSudoku )

Get the subdimension `n` for the Sudoku.
"""
function getn( s::PlainSudoku )::Int
    return s.n
end


"""
    issolution( G::Grid, s::PlainSudoku )

Check whether `G` is a solution for the sudoku `s`.
"""
function issolution( G::Grid, s::PlainSudoku )::Bool
    N = s.N
    n = s.n
    seq1N = Set(1:N)
    return checkgrid( s, G, N )          &&
           checkrows( G, N, seq1N )      &&
           checkcols( G, N, seq1N )      &&
           checkboxees( G, N, n, seq1N )
end


"""
    checkrows( G::Grid, N::Int, seq1N::Set{Int} )

Check whether all rows of `G` are valid, i.e., with no repeated numbers.
"""
function checkrows( G::Grid, N::Int, seq1N::Set{Int} )::Bool
    for i in 1:N
        if Set(G[i,:]) != seq1N
            return false
        end
    end
    return true
end


"""
    checkcols( G::Grid, N::Int, seq1N::Set{Int} )

Check whether all columns of `G` are valid, i.e., with no repeated numbers.
"""
function checkcols( G::Grid, N::Int, seq1N::Set{Int} )::Bool
    for j in 1:N
        if Set(G[:,j]) != seq1N
            return false
        end
    end
    return true
end


"""
    checkboxees( G::Grid, N::Int, n::Int, seq1N::Set{Int} )

Check whether all boxes of `G` are valid, i.e., with no repeated numbers.
"""
function checkboxees( G::Grid, N::Int, n::Int, seq1N::Set{Int} )::Bool
    for i in 1:n:N
        for j in 1:n:N
            i1 = i + n - 1
            j1 = j + n - 1
            if Set(G[i:i1,j:j1]) != seq1N
                return false
            end
        end
    end
    return true
end


"""
    checkgrid( s::PlainSudoku, G::Grid, N::Int )

Check whether the original grid values are correct.
"""
function checkgrid( s::PlainSudoku, G::Grid, N::Int )::Bool
    G0 = s.G
    for i in 1:N
        for j in 1:N
            if G0[i,j] != 0 && G0[i,j] != G[i,j]
                return false
            end
        end
    end
    return true
end


"""
    readsudokufile( ::Type{T}, fname::AbstractString ) where {T <: PlainSudoku}

Build a Plain Sudoku from a file with the following definition format.

Each line corresponds to a row of the sudoku grid where a `.` represents a blank.
# Example:
```
.6...15..
....5..3.
....63..7
.3..7..4.
71.....25
.5..1..9.
2..84....
.9..3....
..41...5.
```
"""
function readsudokufile( ::Type{T}, fname::AbstractString )::T where {T <: PlainSudoku}
    lines = readlines(fname)

    N = length(lines[1])
    if N != length(lines)
        error("grid is not square")
    end

    B = Grid(undef,(N,N))
    for (i, line) in enumerate(lines)
        for (j, c) in enumerate(line)
            if c ≡ '.'
                B[i,j] = 0
            else
                B[i,j] = parse(Int,c)
            end
        end
    end
    return PlainSudoku(B)
end


"""
    writesudokufile( fname::AbstractString, s::PlainSudoku, zeromap=nothing )

Write the Plain Sudoku to file with format as defined in the documentation for
    [`readsudokufile`](@ref) for the `PlainSudoku` method.
"""
function writesudokufile( fname::AbstractString, s::PlainSudoku, zeromap=nothing )
    if zeromap ≡ nothing
        zeromap = x-> x == 0 ? "." : "$x"
    end
    open(fname, "w") do io
        for i in 1:s.N
            for j in 1:s.N
                write(io,"$(zeromap( s.G[i,j] ))")
            end
        end
    end
end


"""
    displaygrid( s::PlainSudoku )

Display the grid for the plain sudoku `s`.

# Examples
```julia-repl
julia> displaygrid(s)
 -------------------------
 | . 6 . | . . 1 | 5 . . |
 | . . . | . 5 . | . 3 . |
 | . . . | . 6 3 | . . 7 |
 -------------------------
 | . 3 . | . 7 . | . 4 . |
 | 7 1 . | . . . | . 2 5 |
 | . 5 . | . 1 . | . 9 . |
 -------------------------
 | 2 . . | 8 4 . | . . . |
 | . 9 . | . 3 . | . . . |
 | . . 4 | 1 . . | . 5 . |
 -------------------------
```
"""
function displaygrid( s::PlainSudoku )
    _displaygrid( s.G, s.N )
end


"""
    availablevalues( _::PlainSudoku, B::Grid, N::Int, n::Int, i::Int, j::Int )

Get a vector with the possible values for grid `B` at position `(i,j)`.
"""
function availablevalues( _::PlainSudoku, B::Grid, N::Int, n::Int, i::Int, j::Int )::Set{Int}
    vals = Set( 1:N )
    # check row i
    setdiff!( vals, B[i,:] )
    # check column j
    setdiff!( vals, B[:,j] )
    # check box containing (i,j)
    i0 = n * ( (i-1) ÷ n ) + 1
    j0 = n * ( (j-1) ÷ n ) + 1
    i1 = i0 + n - 1
    j1 = j0 + n - 1
    setdiff!( vals, B[i0:i1,j0:j1] )
    return vals
end
