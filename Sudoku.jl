"""
Solve plain sudokus and killer sudokus.

Use [`readsudokufile`](@ref) to load a sudoku object and [`solve`](@ref) or [`solve!`](@ref) to
obtain a solution for the sudoku.
"""
module Sudoku

export ASudoku
export PlainSudoku
export KillerSudoku
export BoardT

export readsudokufile
export writesudokufile
export displayboard
export solve
export solve!


"""
Base abstract type for `PlainSudoku` and `KillerSudoku`.
"""
abstract type ASudoku end


include("PlainSudoku.jl")
include("KillerSudoku.jl")


"""
    solve( s::T ) where {T <: ASudoku}

Solve the sudoku `s` and return a board with the solution. If no solution is found, raise an error.
"""
function solve( s::T )::BoardT where {T <: ASudoku}
    B  = copy(getboard(s))
    if !solvestep!( s, B, getN(s), getn(s), 1 )
        error("No solution found.")
    else
        return B
    end
end


"""
    solve!( s::T ) where {T <: ASudoku}

Solve the sudoku `s` in place and return its board with the solution. If no solution is found, raise an error.
"""
function solve!( s::T )::BoardT where {T <: ASudoku}
    B  = getboard(s)
    if !solvestep!( s, B, getN(s), getn(s), 1 )
        error("No solution found.")
    else
        return B
    end
end


"""
    solvestep!( s::T, B::BoardT, N::Int, n::Int, k::Int ) where {T <: ASudoku}

Try to solve one step of the board for position `k` and current board `B`.

The dimensions `N` and `n` are passed to avoid recomputation.
The sudoku object is passed for the call to `availablevalues` which depends on its type.
"""
function solvestep!( s::T, B::BoardT, N::Int, n::Int, k::Int )::Bool where {T <: ASudoku}
    if k > N^2
        return true
    end

    if B[k] != 0
        return solvestep!( s, B, N, n, k+1 )
    end

    # Get row, column from linear index
    j,i = divrem(k-1,N) .+ 1
    vals = availablevalues( s, B, N, n, i, j )
    for m in vals
        B[i,j] = m
        if solvestep!( s, B, N, n, k+1 )
            return true
        end
    end
    B[i,j] = 0
    return false
end


"""
    displayboard( B::BoardT )

Display the board `B`.
"""
function displayboard( B::BoardT )
    N = size(B)[1]
    return _displayboard( B, N )
end


"""
    _displayboard( B::BoardT, N )

Display the board `B` with dimension `N`.
"""
function _displayboard( B::BoardT, N )
    Bmap = x-> x == 0 ? "." : "$x"
    _displayboard( B, N, Bmap )
end


"""
    _displayboard( B::BoardT, N, Bmap )

Display the board `B` with dimension `N` and use the Bmap function to map blanks,
which in `B` are represented by 0.
"""
function _displayboard( B::BoardT, N, Bmap )
    n = Int(round(sqrt(N)))
    k = rem(N,n) == 0 ? 2*(N + div(N,n)) + 1 : 2*(N + div(N,n)) + 3
    linesrt = " "*"-"^k
    for i in 1:N
        if mod(i,n) == 1
            println(linesrt)
        end
        for j in 1:N
            if mod(j,n) == 1
                print(" |")
            end
            print(" $(Bmap( B[i,j] ))")
        end
        println(" |")
    end
    println(linesrt)
end


end # module Sudoku
