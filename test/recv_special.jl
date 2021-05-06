@testset "recv_special.jl" begin
    @testset begin receiver = TCPReceiver(4000)
        @test window_size(receiver) == 4000
        @test ackno(receiver) === nothing
        @test unassembled_bytes(receiver) == 0
        segment_arrives(receiver; with_syn=true, result=SegmentArrives_Result_OK)
        @test ackno(receiver).val == 1
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
    end
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; data="hello", seqno=isn + 1, result=SegmentArrives_Result_NOT_SYN)
    
        @test read!(stream_out(receiver)) == ""
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 1)    
    end
    
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, data="Hello, CS144!", seqno=isn, result=SegmentArrives_Result_OK)
    
        @test read!(stream_out(receiver)) == "Hello, CS144!"
        @test unassembled_bytes(receiver) == 0
        @test ackno(receiver) == WrappingInt32(isn + 14)    
    end
    
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
        @test ackno(receiver) == WrappingInt32(isn + 1)    
    
        segment_arrives(receiver; with_syn=true, seqno=isn + 1, result=SegmentArrives_Result_OK)
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
        @test !stream_out(receiver).has_eof
    
        segment_arrives(receiver; with_syn=true, seqno=isn + 5, result=SegmentArrives_Result_OK)
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
      
        @test !stream_out(receiver).has_eof
    end
    
    
    @testset begin receiver = TCPReceiver(4000)
        isn = rand(UInt32(0):typemax(UInt32))
        text = "Here's a null byte:" * '\0' * "and it's gone.";
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
        
        segment_arrives(receiver; data=text, seqno=isn + 1, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 35)    
        @test read!(stream_out(receiver)) == text
        @test !stream_out(receiver).has_eof
    end
    
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, data="Goodbye, CS144!", with_fin=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @test read!(stream_out(receiver)) == "Goodbye, CS144!"
        @test unassembled_bytes(receiver) == 0
        @test ackno(receiver) == WrappingInt32(isn + 17)
        @test eof(stream_out(receiver))
    end
    
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="oodbye, CS144!", with_fin=true, seqno=isn + 2, result=SegmentArrives_Result_OK)
        
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test !stream_out(receiver).has_eof
        @test read!(stream_out(receiver)) == ""
    
        segment_arrives(receiver; data="G", seqno=isn + 1, result=SegmentArrives_Result_OK)
        
    
        @test read!(stream_out(receiver)) == "Goodbye, CS144!"
        @test ackno(receiver) == WrappingInt32(isn + 17)
        @test eof(stream_out(receiver)) 
    end
    
end

main()

