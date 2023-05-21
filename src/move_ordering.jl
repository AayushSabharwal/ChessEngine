function order_moves(ord::MoveOrderer, abp::AlphaBetaPruning, depth::Int, board::Board, tte, allmoves::MoveList)
    move_values = zero(MVector{length(allmoves),Int})

    for (i, move) in enumerate(allmoves)
        if !isnothing(tte) && move == tte.best_move
            move_values[i] = typemax(Int)
            continue
        elseif move == ord.killers[depth+1]
            move_values[i] = 1<<15
            continue
        end

        exchange_value = see(board, move) * 100 * ord.see_multiplier

        promotion_value = if ispromotion(move)
             PIECE_VALUES[promotion(move).val]
        else
            0
        end

        undoinfo = domove!(board, move)
        check_value = ischeck(board) ? ord.check_value : 0
        undomove!(board, undoinfo)

        if pieceon(board, to(move)) == EMPTY
            move_values[i] += ord.history[ptype(pieceon(board, from(move))).val, to(move).val]
        elseif exchange_value > 0
            move_values[i] += 1<<16
        end

        move_values[i] += exchange_value + promotion_value + check_value
    end

    idxs = zero(MVector{length(allmoves),Int})
    sortperm!(idxs, move_values, rev = true)


    return idxs
end
