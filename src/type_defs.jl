mutable struct ByteStream
    buf::CircularBuffer{UInt8}
    str_arr::Vector{UInt8}
    bytes_written_count::Int
    bytes_read_count::Int
    has_eof::Bool
    error::Bool
    ByteStream(cap::Int) = new(CircularBuffer{UInt8}(cap), zeros(UInt8, cap), 0, 0, false, false)
end

mutable struct StreamReassembler
    output::ByteStream
    unassembled_strings::OrderedSet{Int, String}
    capacity::Int
    cur_idx::Int
    eof_idx::Int
    StreamReassembler(cap::Int) = new(ByteStream(cap), OrderedSet{Int, String}(), cap, 0, 0)
end
