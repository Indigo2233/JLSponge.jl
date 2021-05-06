@testset "recv_transmit.jl" begin
    @testset begin receiver = TCPReceiver(4000)
        segment_arrives(receiver; with_syn=true, seqno=0, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(1)
        segment_arrives(receiver; data="abcd", seqno=1, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(5)
        @test read!(stream_out(receiver)) == "abcd"
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 4
    end
    
    @testset begin receiver = TCPReceiver(4000)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="abcd", seqno=isn+1, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn+5)
        @test read!(stream_out(receiver)) == "abcd"
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 4
    
        segment_arrives(receiver; data="efgh", seqno=isn+5, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn+9)
        @test read!(stream_out(receiver)) == "efgh"
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 8
    end
    
    @testset begin receiver = TCPReceiver(4000)
        isn = rand(UInt32(0):typemax(UInt32))
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        segment_arrives(receiver; data="abcd", seqno=isn+1, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn+5)
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 4
    
        segment_arrives(receiver; data="efgh", seqno=isn+5, result=SegmentArrives_Result_OK)
    
        @test ackno(receiver) == WrappingInt32(isn+9)
        @test read!(stream_out(receiver)) == "abcdefgh"
    
        @test unassembled_bytes(receiver) == 0
        @test assembled_bytes(receiver) == 8
    end
    
    
    @testset begin receiver = TCPReceiver(10000)
        max_block_size = 10
        n_rounds = 100;
        bytes_sent = UInt32(0);
        isn = rand(UInt32(0):typemax(UInt32))
    
        segment_arrives(receiver; with_syn=true, seqno=isn, result=SegmentArrives_Result_OK)
        all_data = ""
        for i in 1:n_rounds
            data = ""
            block_size = rand(1:max_block_size)
            for j in 0:block_size-1
                c = 'a' + ((i + j) % 26)
                data *= c
            end
            all_data *= data
            @test ackno(receiver) == WrappingInt32(isn+bytes_sent+1)
            @test assembled_bytes(receiver) == bytes_sent        
    
            segment_arrives(receiver; seqno=isn+bytes_sent+1, data=data, result=SegmentArrives_Result_OK) 
            bytes_sent += block_size
        end
        @test read!(stream_out(receiver)) == all_data
    
    end    
end

main()
