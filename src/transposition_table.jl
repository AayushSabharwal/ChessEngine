using Random

const PIECE_TO_INDEX = SVector{14}(1, 2, 3, 4, 5, 6, 0, 0, 7, 8, 9, 10, 11, 12)

struct ZobristHasher
    hash_strings::SMatrix{12,64,UInt}
    black_to_move::UInt
end

function ZobristHasher(seed = 42)
    rng = Xoshiro(seed)
    return ZobristHasher(
        SMatrix{12,64}(rand(rng, UInt) for _ in 1:12, _ in 1:64),
        rand(rng, UInt),
    )
end

function zhash(hasher::ZobristHasher, board::Board)
    h = 0
    sidetomove(board) == BLACK && (h ⊻= hasher.black_to_move)

    for i in 1:64
        pc = pieceon(board, Square(i))
        if pc != EMPTY
            h ⊻= hasher.hash_strings[PIECE_TO_INDEX[ptype(pc).val], i]
        end
    end

    return h
end

@enum SearchNodeType Exact UpperBound LowerBound

struct TranspositionTableEntry
    best_move::Move
    best_value::Int
    depth::Int
    type::SearchNodeType
end

struct TranspositionTable
    hasher::ZobristHasher
    table::Dict{UInt,TranspositionTableEntry}
end

TranspositionTable(seed = 42) = TranspositionTable(ZobristHasher(seed), Dict{UInt,TranspositionTableEntry}())

Base.getindex(tb::TranspositionTable, idx::UInt) = getindex(tb.table, idx)

Base.setindex!(tb::TranspositionTable, e::TranspositionTableEntry, idx::UInt) = setindex!(tb.table, e, idx)

Base.haskey(tb::TranspositionTable, idx::UInt) = haskey(tb.table, idx)
