abstract type SearchAlgorithm end

using StaticArrays: sacollect

mutable struct SearchStats
    nodes_visited::Int
    tt_hits::Int
end

SearchStats() = SearchStats(0, 0)

struct MoveOrderer
    check_value::Int
    see_multiplier::Int
    promotion_multiplier::Int
    history::Matrix{Int}
    killers::MVector{50,Move}
    swaplist::MVector{32,Int}
end

function MoveOrderer()
    return MoveOrderer(
        500,
        1,
        1,
        zeros(Int, 12, 64),
        MVector{50}(MOVE_NULL for _ in 1:50),
        zero(MVector{32,Int}),
    )
end

struct AlphaBetaPruning{S} <: SearchAlgorithm
    max_depth::Int
    table::TranspositionTable
    move_orderer::MoveOrderer
    movelist::SVector{S,MoveList}
    moveorder::Matrix{Int}
    movevalues::Matrix{Int}
end

function AlphaBetaPruning(md)
    return AlphaBetaPruning{md + 1}(
        md,
        TranspositionTable(),
        MoveOrderer(),
        sacollect(SVector{md + 1,MoveList}, MoveList(256) for _ in 1:(md + 1)),
        zeros(Int, 256, md + 1),
        zeros(Int, 256, md + 1),
    )
end

function alphabeta_search(
    alg::AlphaBetaPruning, board::Board, depth, α, β, color, stats::SearchStats
)
    stats.nodes_visited += 1
    recycle!(alg.movelist[depth + 1])

    α_orig = α

    idx = ttkey(alg.table, board)
    tte = alg.table[idx]
    depth_to_go = alg.max_depth - depth

    tte == TTE_NULL || (stats.tt_hits += 1)
    if tte != TTE_NULL && tte.depth >= depth_to_go
        if tte.type == Exact
            return tte.best_move, tte.best_value
        elseif tte.type == LowerBound
            α = max(α, tte.best_value)
        else
            β = min(β, tte.best_value)
        end

        if α >= β
            return tte.best_move, tte.best_value
        end
    end

    if isterminal(board)
        if ischeckmate(board)
            return MOVE_NULL, color * -PIECE_VALUES[KING.val]
        else
            return MOVE_NULL, 0
        end
    end

    if depth == alg.max_depth
        return MOVE_NULL, color * evaluate(board)
    end

    moves(board, alg.movelist[depth + 1])
    order_moves(alg.move_orderer, alg, depth, board, tte)

    best_move = MOVE_NULL
    best_value = typemin(Int)
    for i in 1:length(alg.movelist[depth + 1])
        move = alg.movelist[depth + 1][alg.moveorder[i, depth + 1]]

        undoinfo = domove!(board, move)
        _, value = alphabeta_search(alg, board, depth + 1, -β, -α, -color, stats)
        value = -value
        undomove!(board, undoinfo)

        if value > best_value
            best_move = move
            best_value = value
        end

        α = max(α, best_value)
        if β <= α
            if pieceon(board, to(move)) == EMPTY
                alg.move_orderer.killers[depth + 1] = move
                alg.move_orderer.history[
                    ptype(pieceon(board, from(move))).val, to(move).val
                ] += depth_to_go^2
            end
            break
        end
    end

    nodetype = if best_value <= α_orig
        UpperBound
    elseif best_value >= β
        LowerBound
    else
        Exact
    end

    new_tte = TranspositionTableEntry(idx, best_move, best_value, depth_to_go, nodetype)
    alg.table[idx] = new_tte

    return best_move, best_value
end

function search(alg::AlphaBetaPruning, board::Board)
    stats = SearchStats()
    best_move = MOVE_NULL
    best_value = -1
    for i in (alg.max_depth):-1:1
        best_move, best_value = alphabeta_search(
            alg, board, i - 1, -MAX_PIECE_DIFFERENCE, MAX_PIECE_DIFFERENCE, 1, stats
        )
    end

    return stats, best_move, best_value
end
