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

struct TranspositionTableKey
    key_hash::UInt
    check_hash::UInt
end

struct TranspositionTableEntry
    best_move::Move
    best_value::Int
    depth::Int
    type::SearchNodeType
end

struct TranspositionTable
    key_hasher::ZobristHasher
    check_hasher::ZobristHasher
    table::Dict{TranspositionTableKey,TranspositionTableEntry}
end

TranspositionTable(seed = 42) = TranspositionTable(ZobristHasher(seed), ZobristHasher(seed<<1), Dict{UInt,TranspositionTableEntry}())

function ttkey(tt::TranspositionTable, board::Board)
    return TranspositionTableKey(zhash(tt.key_hasher, board), zhash(tt.check_hasher, board))
end

function Base.getindex(tb::TranspositionTable, idx::TranspositionTableKey)
    getindex(tb.table, idx)
end

function Base.setindex!(tb::TranspositionTable, e::TranspositionTableEntry, idx::TranspositionTableKey)
    setindex!(tb.table, e, idx)
end

Base.haskey(tb::TranspositionTable, idx::TranspositionTableKey) = haskey(tb.table, idx)

Base.get(tt::TranspositionTable, idx::TranspositionTableKey, default) = get(tt.table, idx, default)
