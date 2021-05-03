using JLSponge
function main()
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        segment_arrives(receiver; data="abcd", seqno=isn + 10, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
    
        @assert unassembled_bytes(receiver) == 4
        @assert assembled_bytes(receiver) == 0
    end
    
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        segment_arrives(receiver; data="efgh", seqno=isn + 5, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
    
        @assert unassembled_bytes(receiver) == 4
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="abcd", seqno=isn + 1, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 9)
        @assert read!(stream_out(receiver)) == "abcdefgh"
    
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 8
    
    end
    
    
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        segment_arrives(receiver; data="efgh", seqno=isn + 5, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
    
        @assert unassembled_bytes(receiver) == 4
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="ab", seqno=isn + 1, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 3)
        @assert read!(stream_out(receiver)) == "ab"
    
        @assert unassembled_bytes(receiver) == 4
        @assert assembled_bytes(receiver) == 2
    
    
        segment_arrives(receiver; data="cd", seqno=isn + 3, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 9)
        @assert read!(stream_out(receiver)) == "cdefgh"
    
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 8    
    end
    
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 1)
    
        segment_arrives(receiver; data="e", seqno=isn + 5, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
        @assert unassembled_bytes(receiver) == 1
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="g", seqno=isn + 7, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
        @assert unassembled_bytes(receiver) == 2
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="c", seqno=isn + 3, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
        @assert unassembled_bytes(receiver) == 3
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="ab", seqno=isn + 1, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 4)
        @assert read!(stream_out(receiver)) == "abc"
        @assert unassembled_bytes(receiver) == 2
        @assert assembled_bytes(receiver) == 3
    
        segment_arrives(receiver; data="f", seqno=isn + 6, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 4)
        @assert read!(stream_out(receiver)) == ""
        @assert unassembled_bytes(receiver) == 3
        @assert assembled_bytes(receiver) == 3
    
        segment_arrives(receiver; data="d", seqno=isn + 4, result=SegmentArrives_Result_OK)
        @assert read!(stream_out(receiver)) == "defg"
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 7
    end
    
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 1)
    
        segment_arrives(receiver; data="e", seqno=isn + 5, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
        @assert unassembled_bytes(receiver) == 1
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="g", seqno=isn + 7, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
        @assert unassembled_bytes(receiver) == 2
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="c", seqno=isn + 3, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert read!(stream_out(receiver)) == ""
        @assert unassembled_bytes(receiver) == 3
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="abcdefgh", seqno=isn + 1, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 9)
        @assert read!(stream_out(receiver)) == "abcdefgh"
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 8
    end
    
end

main()

