ackno(tr::TCPReceiver)::Union{Nothing,WrappingInt32} = 
    !tr.has_syn ? nothing : wrap(UInt(stream_out(tr).bytes_written_count) + stream_out(tr).has_eof + 1, tr.isn)

window_size(tr::TCPReceiver) = tr.capacity - buffer_size(tr.reassembler.output)

unassembled_bytes(tr::TCPReceiver) = tr.reassembler.unassembled_bytes

stream_out(tr::TCPReceiver) = tr.reassembler.output

assembled_bytes(tr::TCPReceiver) = tr.reassembler.cur_idx

function segment_received!(tr::TCPReceiver, seg::TCPSegment)::Nothing
    header = seg.header
    paload = seg.payload
    if (header.syn)
        tr.has_syn && return
        tr.has_syn = true
        tr.isn = header.seqno
        tr.abs_seqno = 1
        (length_in_sequence_space(seg) == 1) && return
    elseif !tr.has_syn
        return
    else
        tr.abs_seqno = unwrap(header.seqno, tr.isn, tr.abs_seqno)
    end

    (length_in_sequence_space(seg) == 0) && return
    
    push_substring!(tr.reassembler, paload.storage[], tr.abs_seqno - 1, header.fin)
end
