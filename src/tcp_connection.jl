const MAX_RETX_ATTEMPTS = 10

remaining_outbound_capacity(conn::TCPConnection) = remain_cap(conn.sender.stream)

bytes_in_flight(conn::TCPConnection) = bytes_in_flight(conn.sender)

unassembled_bytes(conn::TCPConnection) = unassembled_bytes(conn.receiver)

time_since_last_segment_received(conn::TCPConnection) = conn.time_since_last_segment_received

isactive(conn::TCPConnection) = conn.active

inbound_stream(conn::TCPConnection) = conn.receiver.reassembler.output 

function segment_received!(conn::TCPConnection, seg::TCPSegment)
    !conn.active && return
    conn.time_since_last_segment_received = 0
    # STATE: LISTEN => SYN_RECV
    # receive SYN / send SYN + ACK
    if ackno(conn.receiver) === nothing && next_seqno_absolute(conn.sender) == 0 
        !seg.header.syn && return
        segment_received!(conn.receiver, seg)       
        connect!(conn)
        return
    end
    # STATE: SYN_SENT => ESTABLISED
    # receive SYN + ACK / send ACK
    if ackno(conn.receiver) === nothing && next_seqno_absolute(conn.sender) != 0 &&
        bytes_in_flight(conn.sender) == next_seqno_absolute(conn.sender)
        length(seg.payload) != 0 && return
        if seg.header.syn && !seg.header.ack
            segment_received!(conn.receiver, seg)
            send_empty_segment!(conn.sender)
            send_segs!(conn)
            return
        end
        if seg.header.rst
            set_error(conn.sender.stream)
            set_error(conn.receiver |> stream_in)
            conn.active = false
            return
        end
    end
    # give the seg to receiver
    segment_received!(conn.receiver, seg)
    # tell the sender ackno and window_size
    seg.header.ack && ack_received!(conn.sender, seg.header.ackno, seg.header.win)
    if seg.header.rst
        send_empty_segment!(conn.sender)
        unclean_shutdown!(conn)
        return
    end

    # send at least one segment to reply
    # make sure there is at least one segment
    isempty(conn.sender.segments_out) && (length_in_sequence_space(seg) != 0) &&
        send_empty_segment!(conn.sender)
    # send segments
    send_segs!(conn)
end 

function write!(conn::TCPConnection, data::String)
    write_size = write!(conn.sender.stream, data)
    fill_window!(conn.sender)
    send_segs!(conn)
    write_size
end

function tick!(conn::TCPConnection, ms_since_last_tick::Int)
    !conn.active && return
    conn.time_since_last_segment_received += ms_since_last_tick
    tick!(conn.sender, ms_since_last_tick)
    (consecutive_retransmissions(conn.sender) > MAX_RETX_ATTEMPTS) && unclean_shutdown!(conn) 
    send_segs!(conn)
end

function send_segs!(conn::TCPConnection)
    while conn.sender.segments_out |> !isempty
        seg = dequeue!(conn.sender.segments_out)
        if ackno(conn.receiver) !== nothing
            seg.header.ack = true
            seg.header.ackno = ackno(conn.receiver)
            seg.header.win = window_size(conn.receiver)
        end
        enqueue!(conn.segments_out, seg)
    end
    clean_shutdown!(conn)
end

function end_input_stream!(conn::TCPConnection)
    end_input!(conn.sender.stream)
    fill_window!(conn.sender)
    send_segs!(conn)
end

function connect!(conn::TCPConnection)
    fill_window!(conn.sender)
    send_segs!(conn)
end

function unclean_shutdown!(conn::TCPConnection)
    set_error(conn.sender.stream)
    set_error(conn.receiver |> stream_out)
    conn.active = false
    seg = dequeue!(conn.sender.segments_out)
    if ackno(conn.receiver) !== nothing
        seg.header.ack = true
        seg.header.ackno = ackno(conn.receiver)
        seg.header.win = window_size(conn.receiver)
    end
    seg.header.rst = true
    enqueue!(conn.segments_out, seg)    
end

function clean_shutdown!(conn::TCPConnection)
    !input_ended(stream_out(conn.receiver)) && return
    if !eof(conn.sender.stream)
        conn.linger_after_streams_finish = true
    elseif bytes_in_flight(conn.sender) == 0
        if !conn.linger_after_streams_finish && 
            conn.time_since_last_segment_received >= 10 * conn.rt_timeout
            conn.active = false
        end
    end
end
