function iscapturemove(board::Board, move::Move)
    fpiece = pieceon(board, from(move))
    tpiece = pieceon(board, to(move))
    return tpiece != EMPTY && pcolor(tpiece) != pcolor(fpiece)
end
