const PIECE_VALUES = SVector{7}(100, 300, 300, 500, 900, 50000, 0)
const MAX_PIECE_DIFFERENCE = 64PIECE_VALUES[5]

function evaluate(board::Board)
    cur = sidetomove(board)
    eval = 0
    for i in 1:64
        p = pieceon(board, Square(i))
        eval += (pcolor(p) == cur ? 1 : -1) * PIECE_VALUES[ptype(p).val]
    end
    return eval
end
