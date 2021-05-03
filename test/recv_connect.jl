function main()
    let receiver = TCPReceiver(4000)
        @assert window_size(receiver) == 4000
        @assert ackno(receiver) === nothing
        @assert unassembled_bytes(receiver) == 0
        segment_arrives(receiver; with_syn=true, result=SegmentArrives_Result_OK)
        @assert ackno(receiver).val == 1
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
    end

    let receiver = TCPReceiver(5435)
        @assert ackno(receiver) === nothing
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
        @assert window_size(receiver) == 5435
    
        segment_arrives(receiver; seqno=893475, result=SegmentArrives_Result_NOT_SYN)
        @assert ackno(receiver) === nothing
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
    end
    
    let receiver = TCPReceiver(5435)
        @assert ackno(receiver) === nothing
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
        @assert window_size(receiver) == 5435
    
        segment_arrives(receiver; with_fin=true, with_ack=0, seqno=893475, result=SegmentArrives_Result_NOT_SYN)
        @assert ackno(receiver) === nothing
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
    end

    let receiver = TCPReceiver(5435)
        @assert ackno(receiver) === nothing
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
        @assert window_size(receiver) == 5435
    
        segment_arrives(receiver; with_fin=true, with_ack=0, seqno=893475, result=SegmentArrives_Result_NOT_SYN)
        @assert ackno(receiver) === nothing
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; with_syn=true, seqno=89347598, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(89347599)
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
    end


    let receiver = TCPReceiver(4000)
        segment_arrives(receiver; with_syn=true, seqno=5, with_fin=true, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(7)
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
    end
end

main()