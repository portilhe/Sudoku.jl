"""
Solve plain sudokus and killer sudokus.

Use [`readsudokufile`](@ref) to load a sudoku object and [`solve`](@ref) to obtain a solution for the sudoku.
"""
module Sudoku

export Grid
export ASudoku
export PlainSudoku
export KillerSudoku

export solve
export getgrid
export issolution
export displaygrid
export readsudokufile
export writesudokufile


"""
Base abstract type for `PlainSudoku` and `KillerSudoku`.
"""
abstract type ASudoku end


include("PlainSudoku.jl")
include("KillerSudoku.jl")


"""
    solve( s::T ) where {T <: ASudoku}

Solve the sudoku `s` and return a grid with the solution. If no solution is found, raise an error.
"""
function solve( s::T )::Grid where {T <: ASudoku}
    G  = copy(getgrid(s))
    if !solvestep!( s, G, getN(s), getn(s), 1 )
        error("No solution found.")
    else
        return G
    end
end


"""
    solvestep!( s::T, G::Grid, N::Int, n::Int, k::Int ) where {T <: ASudoku}

Try to solve one step of the grid for position `k` and current grid `G`.

The dimensions `N` and `n` are passed to avoid recomputation.
The sudoku object is passed for the call to `availablevalues` which depends on its type.
"""
function solvestep!( s::T, G::Grid, N::Int, n::Int, k::Int )::Bool where {T <: ASudoku}
    if k > N^2
        return true
    end

    if G[k] != 0
        return solvestep!( s, G, N, n, k+1 )
    end

    # Get row, column from linear index
    j,i = divrem(k-1,N) .+ 1
    vals = availablevalues( s, G, N, n, i, j )
    for m in vals
        G[i,j] = m
        if solvestep!( s, G, N, n, k+1 )
            return true
        end
    end
    G[i,j] = 0
    return false
end


"""
    displaygrid( G::Grid )

Display the grid `G`.
"""
function displaygrid( G::Grid )
    N = size(G)[1]
    return _displaygrid( G, N )
end


"""
    _displaygrid( G::Grid, N )

Display the grid `G` with dimension `N`.
"""
function _displaygrid( G::Grid, N )
    zeromap = x-> x == 0 ? "." : "$x"
    _displaygrid( G, N, zeromap )
end


"""
    _displaygrid( G::Grid, N, zeromap )

Display the grid `G` with dimension `N` and use the zeromap function to map blanks,
which in `G` are represented by 0.
"""
function _displaygrid( G::Grid, N, zeromap )
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
            print(" $(zeromap( G[i,j] ))")
        end
        println(" |")
    end
    println(linesrt)
end


end # module Sudoku
