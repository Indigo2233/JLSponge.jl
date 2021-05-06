@testset "recv_reorder.jl" begin
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 1)
        segment_arrives(receiver; data="abcd", seqno=isn + 10, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
    
        @test unassembled_bytes(receiver) == 4
        @test assembled_bytes(receiver) == 0
    end
    
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 1)
        segment_arrives(receiver; data="efgh", seqno=isn + 5, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
    
        @test unassembled_bytes(receiver) == 4
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="abcd", seqno=isn + 1, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 9)
        @test read!(stream_out(receiver)) == "abcdefgh"
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 8
    
    end
    
    
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 1)
        segment_arrives(receiver; data="efgh", seqno=isn + 5, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
    
        @test unassembled_bytes(receiver) == 4
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="ab", seqno=isn + 1, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 3)
        @test read!(stream_out(receiver)) == "ab"
    
        @test unassembled_bytes(receiver) == 4
        @test assembled_bytes(receiver) == 2
    
    
        segment_arrives(receiver; data="cd", seqno=isn + 3, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 9)
        @test read!(stream_out(receiver)) == "cdefgh"
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 8    
    end
    
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 1)
    
        segment_arrives(receiver; data="e", seqno=isn + 5, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
        @test unassembled_bytes(receiver) == 1
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="g", seqno=isn + 7, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
        @test unassembled_bytes(receiver) == 2
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="c", seqno=isn + 3, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
        @test unassembled_bytes(receiver) == 3
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="ab", seqno=isn + 1, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 4)
        @test read!(stream_out(receiver)) == "abc"
        @test unassembled_bytes(receiver) == 2
        @test assembled_bytes(receiver) == 3
    
        segment_arrives(receiver; data="f", seqno=isn + 6, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 4)
        @test read!(stream_out(receiver)) == ""
        @test unassembled_bytes(receiver) == 3
        @test assembled_bytes(receiver) == 3
    
        segment_arrives(receiver; data="d", seqno=isn + 4, result=SegmentArrives_Result_OK)
        @test read!(stream_out(receiver)) == "defg"
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 7
    end
    
    @testset begin receiver = TCPReceiver(2358)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn + 1)
    
        segment_arrives(receiver; data="e", seqno=isn + 5, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
        @test unassembled_bytes(receiver) == 1
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="g", seqno=isn + 7, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
        @test unassembled_bytes(receiver) == 2
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="c", seqno=isn + 3, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 1)
        @test read!(stream_out(receiver)) == ""
        @test unassembled_bytes(receiver) == 3
        @test assembled_bytes(receiver) == 0
    
        segment_arrives(receiver; data="abcdefgh", seqno=isn + 1, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn + 9)
        @test read!(stream_out(receiver)) == "abcdefgh"
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 8
    end
    
end

main()

