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
    cur_idx::Int
    eof_idx::Int
    StreamReassembler(cap::Int) = return new(ByteStream(cap), OrderedDict{Int,String}(), cap, 0, 0, 0)
end

mutable struct TCPReceiver
    reassembler::StreamReassembler
    capacity::Int
    abs_seqno::Int
    isn::WrappingInt32
    has_syn::Bool
    # has_fin::Bool
    TCPReceiver(cap::Int) = new(StreamReassembler(cap), cap, 0, WrappingInt32(0), false)
end

mutable struct TCPSender
    capacity::Int
    isn::WrappingInt32
    
    segments_out::Queue{TCPSegment}
    outstanding_segs::Vector{TCPSegment}

    initial_retransmission_timeout::Int
    RTO::Int
    ticks::Int
    consecutive_retransmissions::Int

    timer_on::Bool
    fin_flg::Bool
    
    stream::ByteStream

    next_seqno::Int
    last_acked::Int
    bytes_in_flight::Int
    win_size::Int

    TCPSender(;cap::Int=64000, retx_timeout::UInt16=UInt16(1000), fixed_isn=nothing) =
        new(cap, fixed_isn === nothing ? WrappingInt32(rand(1:typemax(UInt32))) : fixed_isn,
        Queue{TCPSegment}(), TCPSegment[], retx_timeout, retx_timeout, 0, 0, 
        false, false, ByteStream(cap), 0, 0, 0, 0)
end

mutable struct TCPConnection
    receiver::TCPReceiver
    sender::TCPSender
    segments_out::Queue{TCPSegment}
    linger_after_streams_finish::Bool
    active::Bool
    rt_timeout::UInt16
    time_since_last_segment_received::Int
    function TCPConnection(;cap::Int=64000, retx_timeout::UInt16=UInt16(1000), fixed_isn=nothing)
        conn = new(TCPReceiver(cap), 
            TCPSender(;cap, retx_timeout, fixed_isn),
            Queue{TCPSegment}(), true, true, 0, UInt16(rt_timeout))
        function f(conn::TCPConnection)
            try
                if conn.active
                    println(stderr, "Warning: Unclean shutdown of TCPConnection")
                    send_empty_segment!(conn)
                    unclean_shutdown!(conn)
                end
            catch e
                println(stderr, "Exception destructing TCP FSM: ", e)
            end
        end
        finalizer(f, conn)
    end
end