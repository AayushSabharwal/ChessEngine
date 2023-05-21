abstract type SearchAlgorithm end

using StaticArrays: sacollect
mutable struct SearchResult
    nodes_visited::Int
    tt_hits::Int
    best_move::Move
    best_value::Int
end

SearchResult(iv) = SearchResult(1, 0, MOVE_NULL, iv)
SearchResult(mv::Move, bv::Int) = SearchResult(1, 0, mv, bv)

function update_stats!(parent::SearchResult, child::SearchResult)
    parent.nodes_visited += child.nodes_visited
    parent.tt_hits += child.tt_hits
end

function update_move!(parent::SearchResult, mv::Move, bv::Int)
    parent.best_move = mv
    parent.best_value = bv
end

function update_move!(parent::SearchResult, child::SearchResult)
    parent.best_move = child.best_move
    parent.best_value = child.best_value
end

struct MoveOrderer
    check_value::Int
    see_multiplier::Int
    promotion_multiplier::Int
    history::MMatrix{12,64,Int}
    killers::MVector{1024,Move}
end

MoveOrderer() = MoveOrderer(500, 1, 1, zero(MMatrix{12,64,Int}), sacollect(MVector{1024,Move}, MOVE_NULL for _ in 1:1024))

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
            return SearchResult(1, 1, tte.best_move, tte.best_value)
        elseif tte.type == LowerBound
            α = max(α, tte.best_value)
        else
            β = min(β, tte.best_value)
        end

        if α >= β
            return SearchResult(1, 1, tte.best_move, tte.best_value)
        end
    end

    if isterminal(board)
        if ischeckmate(board)
            return SearchResult(MOVE_NULL, color * -PIECE_VALUES[KING.val])
        else
            return SearchResult(MOVE_NULL, 0)
        end
    end

    allmoves = moves(board)
    if depth == alg.max_depth
        return SearchResult(MOVE_NULL, color * evaluate(alg.eval, board, allmoves))
    end

    moveordering = order_moves(alg.move_orderer, alg, depth, board, tte, allmoves)

    res = SearchResult(typemin(Int))
    for i in moveordering
        move = allmoves[i]

        undoinfo = domove!(board, move)
        node_res = alphabeta_search(alg, board, depth + 1, -β, -α, -color)
        node_res.best_value *= -1

        undomove!(board, undoinfo)

        update_stats!(res, node_res)

        if node_res.best_value > res.best_value
            update_move!(res, move, node_res.best_value)
        end

        α = max(α, node_res.best_value)
        if β <= α
            if pieceon(board, to(move)) == EMPTY
                alg.move_orderer.killers[depth+1] = move
                alg.move_orderer.history[ptype(pieceon(board, from(move))).val, to(move).val] += depth_to_go ^ 2
            end
            break
        end
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

    isnothing(tte) || (res.tt_hits += 1)
    return res
end

function search(alg::AlphaBetaPruning, board::Board)
    res = SearchResult(0)
    for i in alg.max_depth:-1:1
        _res = alphabeta_search(alg, board, i-1, -MAX_PIECE_DIFFERENCE, MAX_PIECE_DIFFERENCE, 1)
        println(_res)
        update_stats!(res, _res)
        update_move!(res, _res)
    end

    return res
end
