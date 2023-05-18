mutable struct DebugStats
    positions::Int
end

DebugStats() = DebugStats(0)

abstract type SearchAlgorithm end

struct BruteForceSearch
    max_depth::Int
    stats::DebugStats
end

BruteForceSearch(md) = BruteForceSearch(md, DebugStats())

function search(alg::BruteForceSearch, board::Board, eval, depth = 0)
    if isterminal(board)
        if ischeckmate(board)
            if sidetomove(board) == WHITE
                return nothing, -piece_values[KING.val]
            else
                return nothing, piece_values[KING.val]
            end
        else
            return nothing, 0
        end
    end

    alg.stats.positions += 1

    allmoves = moves(board)
    if depth == alg.max_depth
        return nothing, evaluate(eval, board, allmoves)
    end

    side = sidetomove(board)
    best_move = nothing
    best_value = side == WHITE ? typemin(Int) : typemax(Int)
    for move in allmoves
        undoinfo = domove!(board, move)
        _, value = search(alg, board, eval, depth + 1)
        undomove!(board, undoinfo)

        if isnothing(best_move) || side == WHITE && value > best_value || side == BLACK && value < best_value
            best_move = move
            best_value = value
        end
    end

    return best_move, best_value
end

struct AlphaBetaPruning{M<:MoveOrderer}
    max_depth::Int
    table::TranspositionTable
    move_orderer::M
    stats::DebugStats
end

AlphaBetaPruning(md, mo = ChecksCapturesAttacksPromotions()) = AlphaBetaPruning(md, TranspositionTable(), mo, DebugStats())

function _alphabetasearch(alg::AlphaBetaPruning, board::Board, eval, depth, α, β)
    if isterminal(board)
        if ischeckmate(board)
            if sidetomove(board) == WHITE
                return nothing, -piece_values[KING.val]
            else
                return nothing, piece_values[KING.val]
            end
        else
            return nothing, 0
        end
    end

    side = sidetomove(board)

    idx = zhash(alg.table.hasher, board)
    depth_to_go = alg.max_depth - depth
    if haskey(alg.table, idx)
        tte = alg.table[idx]
        if tte.depth >= depth_to_go && (
            tte.type == Exact ||
                side == WHITE && tte.type == LowerBound && tte.best_value >= β ||
                side == BLACK && tte.type == UpperBound && tte.best_value <= α
            )
            return tte.best_move, tte.best_value
        end
    end

    alg.stats.positions += 1

    allmoves = moves(board)
    if depth == alg.max_depth
        return nothing, evaluate(eval, board, allmoves)
    end

    moveordering = order_moves(alg.move_orderer, board, allmoves)
    best_move = nothing
    best_value = side == WHITE ? typemin(Int) : typemax(Int)
    nodetype = Exact

    for i in moveordering
        move = allmoves[i]
        undoinfo = domove!(board, move)
        _, value = _alphabetasearch(alg, board, eval, depth + 1, α, β)
        undomove!(board, undoinfo)

        if side == WHITE
            if value > best_value
                best_move = move
                best_value = value
            end

            α = max(α, value)
            if β <= α
                nodetype = LowerBound
                break
            end
        else
            if value < best_value
                best_move = move
                best_value = value
            end

            β = min(β, value)
            if β <= α
                nodetype = UpperBound
                break
            end
        end
    end

    new_tte = TranspositionTableEntry(best_move, best_value, depth_to_go, nodetype)
    if !haskey(alg.table, idx) || alg.table[idx].depth < depth_to_go || alg.table[idx].depth == depth_to_go && nodetype == Exact && alg.table[idx].type != Exact
        alg.table[idx] = new_tte
    end

    return best_move, best_value
end

function search(alg::AlphaBetaPruning, board::Board, eval, depth = 0)
    return _alphabetasearch(alg, board, eval, depth, typemin(Int), typemax(Int))
end
