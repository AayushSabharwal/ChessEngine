using Random

const PIECE_TO_INDEX = SVector{14}(1, 2, 3, 4, 5, 6, 0, 0, 7, 8, 9, 10, 11, 12)

struct ZobristHasher
    hash_strings::Matrix{UInt}
    black_to_move::UInt
end

function ZobristHasher(seed = 42)
    rng = Xoshiro(seed)
    return ZobristHasher([rand(rng, UInt) for _ in 1:12, _ in 1:64], rand(rng, UInt))
end

function zhash(hasher::ZobristHasher, board::Board)
    h = 0
    sidetomove(board) == BLACK && (h ⊻= hasher.black_to_move)

    for i in 1:64
        pc = pieceon(board, Square(i))
        if pc != EMPTY
            h ⊻= hasher.hash_strings[PIECE_TO_INDEX[pc.val], i]
        end
    end

    return h
end

@enum SearchNodeType Exact UpperBound LowerBound

struct TranspositionTableKey
    idx::UInt
    check::UInt
end

struct TranspositionTableEntry
    check::UInt
    best_move::Move
    best_value::Int
    depth::Int
    type::SearchNodeType
end

function TranspositionTableEntry(
    idx::TranspositionTableKey, best_move, best_value, depth, type
)
    return TranspositionTableEntry(idx.check, best_move, best_value, depth, type)
end

const TTE_NULL = TranspositionTableEntry(UInt(0), MOVE_NULL, typemin(Int), -1, Exact)

struct TranspositionTable
    key_hasher::ZobristHasher
    check_hasher::ZobristHasher
    size::Int
    table::Vector{TranspositionTableEntry}
end

function TranspositionTable(size = 500000, seed = 42)
    tt = TranspositionTable(
        ZobristHasher(seed), ZobristHasher(seed << 1), size, [TTE_NULL for _ in 1:size]
    )
    return tt
end

function ttkey(tt::TranspositionTable, board::Board)
    return TranspositionTableKey(zhash(tt.key_hasher, board), zhash(tt.check_hasher, board))
end

function Base.getindex(tb::TranspositionTable, idx::TranspositionTableKey)
    e = tb.table[mod1(idx.idx, tb.size)]
    return e.check == idx.check ? e : TTE_NULL
end

function Base.setindex!(
    tb::TranspositionTable, e::TranspositionTableEntry, idx::TranspositionTableKey
)
    return tb.table[mod1(idx.idx, tb.size)] = e
end

function Base.haskey(tb::TranspositionTable, idx::TranspositionTableKey)
    return tb.table[mod1(idx.idx, tb.size)].check == idx.check
end
