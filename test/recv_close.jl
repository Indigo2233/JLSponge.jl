function main()
    let receiver = TCPReceiver(4000)
        @assert window_size(receiver) == 4000
        @assert ackno(receiver) === nothing
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+1)
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
        segment_arrives(receiver; with_fin=true, seqno=isn+1, result=SegmentArrives_Result_OK)
        @assert read!(stream_out(receiver)) == ""
        @assert assembled_bytes(receiver) == 0
        @assert eof(stream_out(receiver))
    end

    let receiver = TCPReceiver(4000)
        @assert window_size(receiver) == 4000
        @assert ackno(receiver) === nothing
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+1)
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
        segment_arrives(receiver;data="a", with_fin=true, seqno=isn+1, result=SegmentArrives_Result_OK)
        @assert read!(stream_out(receiver)) == "a"
        @assert assembled_bytes(receiver) == 1
        @assert eof(stream_out(receiver))
    end
    
end

main()

