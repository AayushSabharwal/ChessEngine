function order_moves(ord::MoveOrderer, abp::AlphaBetaPruning, depth::Int, board::Board, tte)
    abp.movevalues[:, depth + 1] .= 0
    for (i, move) in enumerate(abp.movelist[depth + 1])
        if tte != TTE_NULL && move == tte.best_move
            abp.movevalues[i, depth + 1] = typemax(Int)
            continue
        elseif move == ord.killers[depth + 1]
            abp.movevalues[i, depth + 1] = 1 << 15
            continue
        else
            abp.movevalues[i, depth + 1] = 0
        end

        exchange_value = mysee(ord, board, move) * 100 * ord.see_multiplier

        promotion_value = if ispromotion(move)
            PIECE_VALUES[promotion(move).val]
        else
            0
        end

        undoinfo = domove!(board, move)
        check_value = ischeck(board) ? ord.check_value : 0
        undomove!(board, undoinfo)

        if pieceon(board, to(move)) == EMPTY
            abp.movevalues[i, depth + 1] += ord.history[
                ptype(pieceon(board, from(move))).val, to(move).val
            ]
        elseif exchange_value > 0
            abp.movevalues[i, depth + 1] += 1 << 16
        end

        abp.movevalues[i, depth + 1] += exchange_value + promotion_value + check_value
    end

    sortperm!(
        view(abp.moveorder, 1:length(abp.movelist[depth + 1]), depth + 1),
        view(abp.movevalues, 1:length(abp.movelist[depth + 1]), depth + 1);
        rev = true,
    )

    return nothing
end

function mysee(ord::MoveOrderer, b::Board, m::Move)
    values = SVector{14}(1, 3, 3, 5, 10, 100, 0, 0, 1, 3, 3, 5, 10, 100)
    ord.swaplist .= 0

    f = from(m)
    t = to(m)
    piece = pieceon(b, f)
    capture = pieceon(b, t)
    us = sidetomove(b)
    them = coloropp(us)
    occ = occupiedsquares(b) - f
    attackers =
        (rookattacks(occ, t) ∩ rooklike(b)) ∪ (bishopattacks(occ, t) ∩ bishoplike(b)) ∪
        (knightattacks(t) ∩ knights(b)) ∪ (kingattacks(t) ∩ kings(b)) ∪
        (pawnattacks(WHITE, t) ∩ pawns(b, BLACK)) ∪
        (pawnattacks(BLACK, t) ∩ pawns(b, WHITE))
    attackers = attackers ∩ occ

    if attackers ∩ pieces(b, them) == SS_EMPTY
        return capture == EMPTY ? 0 : values[capture.val]
    end
    c = them
    n = 2
    lastcapval = values[piece.val]
    ord.swaplist[1] = capture == EMPTY ? 0 : values[capture.val]

    while true
        pt = PAWN
        ss = attackers ∩ pieces(b, c, pt)
        while ss == SS_EMPTY
            pt = PieceType(pt.val + 1)
            ss = attackers ∩ pieces(b, c, pt)
        end
        occ -= first(ss)
        attackers =
            attackers ∪ (rookattacks(occ, t) ∩ rooklike(b)) ∪
            (bishopattacks(occ, t) ∩ bishoplike(b))
        attackers = attackers ∩ occ
        ord.swaplist[n] = -ord.swaplist[n - 1] + lastcapval
        c = coloropp(c)

        if attackers ∩ pieces(b, c) == SS_EMPTY
            break
        end
        n += 1

        if pt == KING
            ord.swaplist[n] = 100
            break
        end
        lastcapval = values[pt.val]
    end

    while n >= 2
        ord.swaplist[n - 1] = min(-ord.swaplist[n], ord.swaplist[n - 1])
        n -= 1
    end
    return ord.swaplist[1]
end
