mutable struct RotatingBuffer{S,T}
    buffer::MVector{S,T}
    idx::Int
end

function RotatingBuffer{S,T}(el = zero(T)) where {S,T}
    return RotatingBuffer{S,T}(sacollect(MVector{S,T}, el for _ in 1:S), 1)
end

function add_to_buffer!(buffer::RotatingBuffer{S,T}, el::T) where {S,T}
    buffer.buffer[buffer.idx] = el
    buffer.idx = mod1(buffer.idx + 1, S)
    return buffer
end

Base.getindex(buffer::RotatingBuffer, idx::Int) = getindex(buffer.buffer, idx)

Base.in(el::T, buffer::RotatingBuffer{S,T}) where {S,T} = in(el, buffer.buffer)
