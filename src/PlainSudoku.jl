"""
Type alias for the board of a sudoku, which is always a square matrix.
"""
BoardT  = Matrix{Int}


"""
Define a plain Sudoku from a given borad state.

# Attributes
- `B::BoardT`: The board.
- `N::Int`: The dimension of the side of the board.
- `n:Int`: The subdimension of the side of the board, `sqrt(N)`.
"""
mutable struct PlainSudoku <: ASudoku
    B::BoardT
    N::Int
    n::Int
    function PlainSudoku( B::BoardT )
        N, _N = size(B)
        if N != _N
            error( "board is not square" )
        end
        n = Int(round(sqrt(N)))
        return new( B, N, n )
    end
end


"""
    getboard( s::PlainSudoku )

Get the board for the Sudoku.
"""
function getboard( s::PlainSudoku )::BoardT
    return s.B
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
    readsudokufile( ::Type{T}, fname::AbstractString ) where {T <: PlainSudoku}

Build a Plain Sudoku from a file with the following definition format.

Each line corresponds to a row of the sudoku board where a `.` represents a blank.
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
function readsudokufile( ::Type{T}, fname::AbstractString )::PlainSudoku where {T <: PlainSudoku}
    lines = readlines(fname)

    N = length(lines[1])
    if N != length(lines)
        error("board is not square")
    end

    B = BoardT(undef,(N,N))
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
    writesudokufile( fname::AbstractString, s::PlainSudoku, Bmap=nothing )

Write the Plain Sudoku to file with format as defined in the documentation for
    [`readsudokufile`](@ref) for the `PlainSudoku` method.
"""
function writesudokufile( fname::AbstractString, s::PlainSudoku, Bmap=nothing )
    if Bmap ≡ nothing
        Bmap = x-> x == 0 ? "." : "$x"
    end
    open(fname, "w") do io
        for i in 1:s.N
            for j in 1:s.N
                write(io,"$(Bmap( s.B[i,j] ))")
            end
        end
    end
end


"""
    displayboard( s::PlainSudoku )

Display the board for the plain sudoku `s`.

# Examples
```julia-repl
julia> displayboard(s)
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
function displayboard( s::PlainSudoku )
    _displayboard( s.B, s.N )
end


"""
    availablevalues( _::PlainSudoku, B::BoardT, N::Int, n::Int, i::Int, j::Int )

Get a vector with the possible values for board `B` at position `(i,j)`.
"""
function availablevalues( _::PlainSudoku, B::BoardT, N::Int, n::Int, i::Int, j::Int )::Set{Int}
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
