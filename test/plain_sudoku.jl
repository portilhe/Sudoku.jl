
for sudoku_file in ["sudoku1.txt", "sudoku2.txt"]
    println("   * $(sudoku_file)")
    sudoku = readsudokufile( PlainSudoku, joinpath( @__DIR__, sudoku_file ) )

    println("\n\n"*"-"^80)
    println("Solving:")
    displaygrid(sudoku)

    solG = solve(sudoku)
    @test solG != getgrid(sudoku)

    @test issolution( solG, sudoku )

    println("\nSolution ==>")
    displaygrid(solG)
end