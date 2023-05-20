const PIECE_VALUES = SVector{7}(100, 300, 300, 500, 900, 50000, 0)
const MAX_PIECE_DIFFERENCE = 64PIECE_VALUES[5]

color_to_sign(p::PieceColor) = color_to_sign(Val(p))
color_to_sign(::Val{WHITE}) = 1
color_to_sign(::Val{BLACK}) = -1

abstract type BoardEvaluator end

struct PieceDifference <: BoardEvaluator end

function evaluate(::PieceDifference, board::Board, moves::MoveList)
    cur = sidetomove(board)
    next = coloropp(cur)
    return sum(
        squarecount(pfunc(board, cur) - pfunc(board, next)) * PIECE_VALUES[i]
        for (i, pfunc) in enumerate((pawns, knights, bishops, rooks, queens))
    )
end

struct PieceMobility <: BoardEvaluator end

function evaluate(::PieceMobility, board::Board, moves::MoveList)
    mymoves = movecount(board)
    if ischeck(board)
        undoinfo = domove!(board, moves[1])
        othermoves = movecount(board)
        undomove!(board, undoinfo)
    else
        othermoves = movecount(board)
    end

    return mymoves - othermoves
end
