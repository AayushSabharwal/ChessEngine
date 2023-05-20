function order_moves(ord::MoveOrderer, abp::AlphaBetaPruning, board::Board, allmoves::MoveList)
    move_values = zero(MVector{length(allmoves),Int})

    for (i, move) in enumerate(allmoves)
        move_values[i] += see(board, move) * 100 * ord.see_multiplier

        if ispromotion(move)
            move_values[i] += PIECE_VALUES[promotion(move).val]
        end

        undoinfo = domove!(board, move)
        ischeck(board) && (move_values[i] += ord.check_value)
        undomove!(board, undoinfo)
    end

    idxs = zero(MVector{length(allmoves),Int})
    sortperm!(idxs, move_values, rev = true)
    return idxs
end
