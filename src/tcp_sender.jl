const MAX_PAYLOAD_SIZE = 1000

bytes_in_flight(sender::TCPSender) = sender.bytes_in_flight

next_seqno_absolute(sender::TCPSender) = sender.next_seqno

next_seqno(sender::TCPSender) = wrap(sender.next_seqno |> UInt, sender.isn)

segments_out(sender::TCPSender) = sender.segments_out

stream_in(sender::TCPSender) = sender.stream

function fill_window!(sender::TCPSender)
    (sender.next_seqno == 0) && 
        send_seg!(sender, TCPSegment(TCPHeader(syn=true), ""))
    win = sender.win_size > 0 ? sender.win_size : 1
    remain = 0
    # (win < sender.next_seqno - sender.last_acked) && return
    while (remain = win - (sender.next_seqno - sender.last_acked)) > 0 && !sender.fin_flg
        sz = min(MAX_PAYLOAD_SIZE, remain)
        seg = TCPSegment(read!(sender.stream, sz))
        if length_in_sequence_space(seg) < win && eof(sender.stream)
            seg.header.fin = sender.fin_flg = true
        end
        (length_in_sequence_space(seg) == 0) && break
        send_seg!(sender, seg)
    end
end

function send_seg!(sender::TCPSender, seg::TCPSegment)
    header = seg.header
    header.seqno = next_seqno(sender)
    header.syn = sender.next_seqno == 0

    len = length_in_sequence_space(seg)
    sender.next_seqno += len
    sender.bytes_in_flight += len

    enqueue!(sender.segments_out, seg)
    push!(sender.outstanding_segs, seg)
    sender.timer_on = true
end

function ack_received!(sender::TCPSender, ackno::WrappingInt32, win_size::UInt16)
    abs_ackno = unwrap(ackno, sender.isn, sender.last_acked)
    sender.win_size = win_size
    (abs_ackno <= sender.last_acked || abs_ackno > sender.next_seqno) && return
    i = 0
    acc = sender.last_acked
    len = length(sender.outstanding_segs)
    while i <= len && acc < abs_ackno
        i += 1
        @inbounds acc += length_in_sequence_space(sender.outstanding_segs[i])
    end
    if acc > abs_ackno
        acc -= length_in_sequence_space(sender.outstanding_segs[i])
        i -= 1
    end
    (i == 0) && return
    sender.bytes_in_flight -= (acc - sender.last_acked)
    deleteat!(sender.outstanding_segs, 1:i)
    sender.last_acked = acc
    sender.timer_on = false
    sender.RTO = sender.initial_retransmission_timeout
    sender.ticks = 0

    fill_window!(sender)   
    !isempty(sender.outstanding_segs) && (sender.timer_on = true)    
end

function tick!(sender::TCPSender, ms_since_last_tick::Int)
    !sender.timer_on && return
    sender.ticks += ms_since_last_tick
    if sender.ticks >= sender.RTO && !isempty(sender.outstanding_segs)
        enqueue!(sender.segments_out, sender.outstanding_segs[1])
        if sender.last_acked == 0 || sender.win_size != 0
            sender.consecutive_retransmissions += 1
            sender.RTO <<= 1
        end
        sender.ticks = 0        
    end
    if isempty(sender.outstanding_segs)
        sender.timer_on = false
        sender.ticks = 0
    end    
end

consecutive_retransmissions(sender::TCPSender) = sender.consecutive_retransmissions

send_empty_segment!(sender::TCPSender) =
    enqueue!(sender.segments_out, TCPSegment(TCPHeader(seqno=wrap(sender.next_seqno, sender.isn)) ,""))
