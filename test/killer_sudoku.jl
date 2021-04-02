
for sudoku_file in ["killer_sudoku1.txt", "killer_sudoku2.txt"]
    println("   * $(sudoku_file)")
    sudoku = readsudokufile( KillerSudoku, joinpath( @__DIR__, sudoku_file ) )

    println("\n\n"*"-"^80)
    println("Solving:")
    displaygrid(sudoku)

    solG = solve(sudoku)
    @test solG != getgrid(sudoku)

    @test issolution( solG, sudoku )

    println("\nSolution ==>")
    displaygrid(solG)
end