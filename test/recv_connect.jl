@testset "recv_connect.jl" begin
    @testset begin receiver = TCPReceiver(4000)
        @test window_size(receiver) == 4000
        @test ackno(receiver) === nothing
        @test unassembled_bytes(receiver) == 0
        segment_arrives(receiver; with_syn=true, result=SegmentArrives_Result_OK)
        @test ackno(receiver).val == 1
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
    end

    @testset begin receiver = TCPReceiver(5435)
        @test ackno(receiver) === nothing
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
        @test window_size(receiver) == 5435

        segment_arrives(receiver; seqno=893475, result=SegmentArrives_Result_NOT_SYN)
        @test ackno(receiver) === nothing
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
    end

    @testset begin receiver = TCPReceiver(5435)
        @test ackno(receiver) === nothing
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
        @test window_size(receiver) == 5435

        segment_arrives(receiver; with_fin=true, with_ack=0, seqno=893475, result=SegmentArrives_Result_NOT_SYN)
        @test ackno(receiver) === nothing
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
    end

    @testset begin receiver = TCPReceiver(5435)
        @test ackno(receiver) === nothing
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
        @test window_size(receiver) == 5435

        segment_arrives(receiver; with_fin=true, with_ack=0, seqno=893475, result=SegmentArrives_Result_NOT_SYN)
        @test ackno(receiver) === nothing
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0

        segment_arrives(receiver; with_syn=true, seqno=89347598, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(89347599)
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
    end


    @testset begin receiver = TCPReceiver(4000)
        segment_arrives(receiver; with_syn=true, seqno=5, with_fin=true, result=SegmentArrives_Result_OK)
        @test ackno(receiver) == WrappingInt32(7)
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 0
    end
end