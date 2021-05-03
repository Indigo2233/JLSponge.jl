function main()
    let receiver = TCPReceiver(4000)
        cap = 4000
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+1)
        @assert window_size(receiver) == cap
    
        segment_arrives(receiver; data="abcd", seqno=isn+1, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+5)
        @assert window_size(receiver) == cap - 4
        
        segment_arrives(receiver; data="ijkl", seqno=isn+9, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+5)
        @assert window_size(receiver) == cap - 4
    
        segment_arrives(receiver; data="ijkl", seqno=isn+5, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+13)
        @assert window_size(receiver) == cap - 12
    end
    
    let receiver = TCPReceiver(4000)
        cap = 4000
        isn = rand(UInt32(0):typemax(UInt32))
        
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+1)
        @assert window_size(receiver) == cap
    
        segment_arrives(receiver; data="abcd", seqno=isn+1, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+5)
        @assert window_size(receiver) == cap - 4
        
        @assert read!(stream_out(receiver)) == "abcd"
        @assert ackno(receiver) == WrappingInt32(isn+5)
        @assert window_size(receiver) == cap
    end
    
    
    let receiver = TCPReceiver(2)
        cap = 2
        isn = rand(UInt32(0):typemax(UInt32))
        
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+1)
        @assert window_size(receiver) == cap
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="cd", seqno=isn+3)
        @assert ackno(receiver) == WrappingInt32(isn+1)
        @assert window_size(receiver) == cap
        @assert assembled_bytes(receiver) == 0
    end
    
    let receiver = TCPReceiver(2)
        cap = 2
        isn = rand(UInt32(0):typemax(UInt32))
        
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+1)
        @assert window_size(receiver) == cap
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="bc", seqno=isn+2, result=SegmentArrives_Result_OK)
        @assert assembled_bytes(receiver) == 0
        segment_arrives(receiver; data="a", seqno=isn+1, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+3)
        @assert window_size(receiver) == 0
        @assert assembled_bytes(receiver) == 2
        @assert read!(stream_out(receiver)) == "ab"
        @assert window_size(receiver) == 2
        
    end
    
    let receiver = TCPReceiver(4)
        cap = 4
        isn = rand(UInt32(0):typemax(UInt32))
        
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @assert ackno(receiver) == WrappingInt32(isn+1)
        @assert window_size(receiver) == cap
        @assert assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="ab", seqno=isn+1, result=SegmentArrives_Result_OK)
        @assert assembled_bytes(receiver) == 2
        @assert window_size(receiver) == cap-2
        segment_arrives(receiver; data="abc", seqno=isn+1, result=SegmentArrives_Result_OK)
        @assert assembled_bytes(receiver) == 3
        @assert window_size(receiver) == cap-3
        
    end
    
    let receiver = TCPReceiver(4)
        cap = 4
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="ab", seqno=isn+1, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="cdef", seqno=isn+3, result=SegmentArrives_Result_OK)
    end
    
    let receiver = TCPReceiver(4)
        cap = 4
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="ab", seqno=isn+1, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="cd", seqno=isn+3, result=SegmentArrives_Result_OK)
    end
    
    let receiver = TCPReceiver(4)
        cap = 4
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="a", seqno=isn, result=SegmentArrives_Result_OK)
    end        
end

main()