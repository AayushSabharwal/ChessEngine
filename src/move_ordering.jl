abstract type MoveOrderer end

struct IdentityOrderer <: MoveOrderer end

function order_moves(::IdentityOrderer, ::Board, allmoves::MoveList)
    return MVector{length(allmoves)}(1:length(allmoves))
end

struct ChecksCapturesAttacksPromotions <: MoveOrderer
    check_value::Int
    see_multiplier::Int
    promotion_multiplier::Int
end

ChecksCapturesAttacksPromotions() = ChecksCapturesAttacksPromotions(300, 1, 1)

function order_moves(alg::ChecksCapturesAttacksPromotions, board::Board, allmoves::MoveList)
    move_values = zero(MVector{length(allmoves),Int})

    for (i, move) in enumerate(allmoves)
        move_values[i] += see(board, move) * 100 * alg.see_multiplier

        if ispromotion(move)
            move_values[i] += piece_values[promotion(move).val]
        end

        undoinfo = domove!(board, move)
        ischeck(board) && (move_values[i] += alg.check_value)
        undomove!(board, undoinfo)
    end

    idxs = zero(MVector{length(allmoves),Int})
    sortperm!(idxs, move_values, rev = true)
    return idxs
end
