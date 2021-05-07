@testset "send_retx.jl" begin
    @testset "Retx SYN twice at the right times, then ack" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)
    
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        tick!(sender, rto - 1)
        expect_no_seg(sender)
        tick!(sender, 1)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_state(sender, JLSponge.SYN_SENT)
        @test sender.bytes_in_flight == 1
        
        tick!(sender, 2rto - 1)
        expect_no_seg(sender)
        tick!(sender, 1)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_state(sender, JLSponge.SYN_SENT)
        @test sender.bytes_in_flight == 1
        ack_received_test(sender, WrappingInt32(isn+1))
        @test sender.bytes_in_flight == 0
    end
     
    @testset "Retx SYN until too many retransmissions" begin 
        MAX_RETX_ATTEMPTS = 10
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)
    
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        expect_state(sender, JLSponge.SYN_SENT)
    
        for i in 0:MAX_RETX_ATTEMPTS-1
            tick!(sender, (Int(rto) << i) - 1)
            @test sender.consecutive_retransmissions <= MAX_RETX_ATTEMPTS
            tick!(sender, 1)
            expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
            expect_no_seg(sender)
            expect_state(sender, JLSponge.SYN_SENT)
            @test sender.bytes_in_flight == 1
        end
        tick!(sender, (Int(rto) << MAX_RETX_ATTEMPTS) - 1)
        @test sender.consecutive_retransmissions <= MAX_RETX_ATTEMPTS
        tick!(sender, 1)
        @test sender.consecutive_retransmissions > MAX_RETX_ATTEMPTS
    end

    @testset "Send some data, the retx and succeed, then retx till limit" begin 
        MAX_RETX_ATTEMPTS = 10
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)
    
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn+1))
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "abcd")
        expect_seg(sender, payload_size=4)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn+5))
        @test sender.bytes_in_flight == 0
        write_bytes!(sender, "efgh")
        expect_seg(sender, payload_size=4)
        expect_no_seg(sender)
        @test sender.consecutive_retransmissions <= MAX_RETX_ATTEMPTS
        ack_received_test(sender, WrappingInt32(isn+9))
        @test sender.bytes_in_flight == 0
    
        write_bytes!(sender, "efgh")
        expect_seg(sender, payload_size=4, seqno=WrappingInt32(isn+9))
        expect_no_seg(sender)
        
        for i in 0:MAX_RETX_ATTEMPTS-1
            tick!(sender, (Int(rto) << i) - 1)
            @test sender.consecutive_retransmissions <= MAX_RETX_ATTEMPTS
            expect_no_seg(sender)
            tick!(sender, 1)
            expect_seg(sender, payload_size=4, seqno=WrappingInt32(isn + 9))
            expect_no_seg(sender)
            expect_state(sender, JLSponge.SYN_ACKED)
            @test sender.bytes_in_flight == 4
        end
    
        tick!(sender, (Int(rto) << MAX_RETX_ATTEMPTS) - 1)
        @test sender.consecutive_retransmissions <= MAX_RETX_ATTEMPTS
        tick!(sender, 1)
        @test sender.consecutive_retransmissions > MAX_RETX_ATTEMPTS
    end    
end