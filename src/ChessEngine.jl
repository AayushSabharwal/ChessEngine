module ChessEngine

using Chess
using StaticArrays

include("utils.jl")
include("evaluate.jl")
include("transposition_table.jl")
include("move_ordering.jl")
include("search.jl")


end
