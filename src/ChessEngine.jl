module ChessEngine

using Chess
using StaticArrays

include("utils.jl")
include("transposition_table.jl")
include("evaluate.jl")
include("search.jl")
include("move_ordering.jl")
include("test_ttd.jl")

end
