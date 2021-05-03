mutable struct ByteStream
    buf::CircularBuffer{UInt8}
    str_arr::Vector{UInt8}
    bytes_written_count::Int
    bytes_read_count::Int
    has_eof::Bool
    error::Bool
    function ByteStream(cap::Int)
        return new(CircularBuffer{UInt8}(cap), zeros(UInt8, cap), 0, 0, false, false)
    end
end

mutable struct StreamReassembler
    output::ByteStream
    unassembled_strings::SortedDict{Int,String}
    capacity::Int
    unassembled_bytes::Int
    capacity::Int
    unassembled_bytes::Int
    cur_idx::Int
    eof_idx::Int
    function StreamReassembler(cap::Int)
        return new(ByteStream(cap), OrderedDict{Int,String}(), cap, 0, 0, 0)
    end
end

mutable struct TCPReceiver
    reassembler::StreamReassembler
    capacity::Int
    abs_seqno::Int
    isn::WrappingInt32
    has_syn::Bool
    # has_fin::Bool
    TCPReceiver(cap::Int) = new(StreamReassembler(cap), cap, 0, 0, false)
end
