abstract type SearchAlgorithm end

mutable struct SearchResult
    nodes_visited::Int
    best_move::Move
    best_value::Int
end

SearchResult(iv) = SearchResult(0, MOVE_NULL, iv)

struct MoveOrderer
    check_value::Int
    see_multiplier::Int
    promotion_multiplier::Int
end

MoveOrderer() = MoveOrderer(300, 1, 1)

struct AlphaBetaPruning{E<:BoardEvaluator} <: SearchAlgorithm
    max_depth::Int
    eval::E
    table::TranspositionTable
    move_orderer::MoveOrderer
end

AlphaBetaPruning(md) = AlphaBetaPruning(md, PieceDifference(), TranspositionTable(), MoveOrderer())

function alphabeta_search(alg::AlphaBetaPruning, board::Board, depth, α, β, color)
    α_orig = α

    idx = ttkey(alg.table, board)
    tte = get(alg.table, idx, nothing)

    depth_to_go = alg.max_depth - depth
    if !isnothing(tte) && tte.depth >= depth_to_go
        if tte.type == Exact
            return SearchResult(1, tte.best_move, tte.best_value)
        elseif tte.type == LowerBound
            α = max(α, tte.best_value)
        else
            β = min(β, tte.best_value)
        end

        if α >= β
            return SearchResult(1, tte.best_move, tte.best_value)
        end
    end

    if isterminal(board)
        if ischeckmate(board)
            return SearchResult(1, MOVE_NULL, color * -PIECE_VALUES[KING.val])
        else
            return SearchResult(1, MOVE_NULL, 0)
        end
    end

    allmoves = moves(board)
    if depth == alg.max_depth
        return SearchResult(1, MOVE_NULL, color * evaluate(alg.eval, board, allmoves))
    end

    moveordering = order_moves(alg.move_orderer, alg, board, allmoves)
    res = SearchResult(typemin(Int))
    for i in moveordering
        move = allmoves[i]

        undoinfo = domove!(board, move)
        node_res = alphabeta_search(alg, board, depth + 1, -β, -α, -color)
        node_res.best_value *= -1

        undomove!(board, undoinfo)

        res.nodes_visited += node_res.nodes_visited

        if node_res.best_value > res.best_value
            res.best_move = move
            res.best_value = node_res.best_value
        end

        α = max(α, node_res.best_value)
        β <= α && break
    end

    nodetype = if res.best_value <= α_orig
        UpperBound
    elseif res.best_value >= β
        LowerBound
    else
        Exact
    end

    new_tte = TranspositionTableEntry(res.best_move, res.best_value, depth_to_go, nodetype)
    alg.table[idx] = new_tte

    return res
end

function search(alg::AlphaBetaPruning, board::Board)
    return alphabeta_search(alg, board, 0, -MAX_PIECE_DIFFERENCE, MAX_PIECE_DIFFERENCE, 1)
end
