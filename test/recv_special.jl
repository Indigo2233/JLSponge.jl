using JLSponge
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
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; data="hello", seqno=isn + 1, result=SegmentArrives_Result_NOT_SYN)
    
        @assert read!(stream_out(receiver)) == ""
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn + 1)    
    end
    
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, data="Hello, CS144!", seqno=isn, result=SegmentArrives_Result_OK)
    
        @assert read!(stream_out(receiver)) == "Hello, CS144!"
        @assert unassembled_bytes(receiver) == 0
        @assert ackno(receiver) == WrappingInt32(isn + 14)    
    end
    
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
        @assert ackno(receiver) == WrappingInt32(isn + 1)    
    
        segment_arrives(receiver; with_syn=true, seqno=isn + 1, result=SegmentArrives_Result_OK)
    
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
        @assert !stream_out(receiver).has_eof
    
        segment_arrives(receiver; with_syn=true, seqno=isn + 5, result=SegmentArrives_Result_OK)
    
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
      
        @assert !stream_out(receiver).has_eof
    end
    
    
    let receiver = TCPReceiver(4000)
        isn = rand(UInt32(0):typemax(UInt32))
        text = "Here's a null byte:" * '\0' * "and it's gone.";
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert unassembled_bytes(receiver) == 0
        @assert assembled_bytes(receiver) == 0
        
        segment_arrives(receiver; data=text, seqno=isn + 1, result=SegmentArrives_Result_OK)
    
        @assert ackno(receiver) == WrappingInt32(isn + 35)    
        @assert read!(stream_out(receiver)) == text
        @assert !stream_out(receiver).has_eof
    end
    
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, data="Goodbye, CS144!", with_fin=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @assert read!(stream_out(receiver)) == "Goodbye, CS144!"
        @assert unassembled_bytes(receiver) == 0
        @assert ackno(receiver) == WrappingInt32(isn + 17)
        @assert eof(stream_out(receiver))
    end
    
    let receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="oodbye, CS144!", with_fin=true, seqno=isn + 2, result=SegmentArrives_Result_OK)
        
        @assert ackno(receiver) == WrappingInt32(isn + 1)
        @assert !stream_out(receiver).has_eof
        @assert read!(stream_out(receiver)) == ""
    
        segment_arrives(receiver; data="G", seqno=isn + 1, result=SegmentArrives_Result_OK)
        
    
        @assert read!(stream_out(receiver)) == "Goodbye, CS144!"
        @assert ackno(receiver) == WrappingInt32(isn + 17)
        @assert eof(stream_out(receiver)) 
    end
    
end

main()

