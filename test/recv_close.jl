@testset "recv_close.jl" begin
    @testset begin receiver = TCPReceiver(4000)
        @test window_size(receiver) == 4000
        @test ackno(receiver) === nothing
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn+1)
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
        segment_arrives(receiver; with_fin=true, seqno=isn+1, result=SegmentArrives_Result_OK)
        @test read!(stream_out(receiver)) == ""
        @test assembled_bytes(receiver) == 0
        @test eof(stream_out(receiver))
    end

    @testset begin receiver = TCPReceiver(4000)
        @test window_size(receiver) == 4000
        @test ackno(receiver) === nothing
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(isn+1)
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
        segment_arrives(receiver;data="a", with_fin=true, seqno=isn+1, result=SegmentArrives_Result_OK)
        @test read!(stream_out(receiver)) == "a"
        @test assembled_bytes(receiver) == 1
        @test eof(stream_out(receiver))
    end
end
