include("../src/Sudoku.jl")

using Test
using .Sudoku

my_tests = ["plain_sudoku.jl", "killer_sudoku.jl"]
#my_tests = ["plain_sudoku.jl"]

println("Running tests:")

@testset "Sudoku" begin
    for my_test in my_tests
        println(" * $(my_test)")
        include(my_test)
    end
end
