const piece_values = SVector{7}(100, 300, 300, 500, 900, 50000, 0)

abstract type BoardEvaluator end

struct PieceDifference <: BoardEvaluator end

function evaluate(::PieceDifference, board::Board, moves::MoveList)
    return sum(
        squarecount(pfunc(board, WHITE) - pfunc(board, BLACK)) * piece_values[i]
        for (i, pfunc) in enumerate((pawns, knights, bishops, rooks, queens))
    )
end
