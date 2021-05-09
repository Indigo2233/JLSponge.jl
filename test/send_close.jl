@testset "send_close.jl" begin
    @testset "FIN sent test" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.SYN_ACKED)
        sender_close(sender)
        expect_state(sender, JLSponge.FIN_SENT)
        @test sender.bytes_in_flight == 1
        expect_seg(sender, fin=true, seqno=WrappingInt32(isn + 1))
    end

    @testset "FIN acked test" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.SYN_ACKED)
        sender_close(sender)
        expect_state(sender, JLSponge.FIN_SENT)
        expect_seg(sender, fin=true, seqno=WrappingInt32(isn + 1))
        ack_received_test(sender, WrappingInt32(isn + 2))
        expect_state(sender, JLSponge.FIN_ACKED)
        @test sender.bytes_in_flight == 0
        expect_no_seg(sender)
    end
    @testset "FIN not acked test" begin
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.SYN_ACKED)
        sender_close(sender)
        expect_state(sender, JLSponge.FIN_SENT)
        expect_seg(sender, fin=true, seqno=WrappingInt32(isn + 1))
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.FIN_SENT)
        @test sender.bytes_in_flight == 1
        expect_no_seg(sender) 
    end

    @testset "FIN retx test" begin
        TIMEOUT_DFLT = UInt16(1000)
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(;fixed_isn=WrappingInt32(isn), retx_timeout=TIMEOUT_DFLT)
        fill_window!(sender)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.SYN_ACKED)
        sender_close(sender)
        expect_state(sender, JLSponge.FIN_SENT)
        expect_seg(sender, fin=true, seqno=WrappingInt32(isn + 1))
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.FIN_SENT)
        @test sender.bytes_in_flight == 1
        expect_no_seg(sender)
        tick!(sender, TIMEOUT_DFLT - 1)
        expect_state(sender, JLSponge.FIN_SENT)
        @test sender.bytes_in_flight == 1
        expect_no_seg(sender)

        tick!(sender, 1)
        expect_state(sender, JLSponge.FIN_SENT)
        @test sender.bytes_in_flight == 1
        expect_seg(sender, fin=true, seqno=WrappingInt32(isn + 1))
        expect_no_seg(sender)
        tick!(sender, 1)
        expect_state(sender, JLSponge.FIN_SENT)
        @test sender.bytes_in_flight == 1
        expect_no_seg(sender)
        
        ack_received_test(sender, WrappingInt32(isn + 2))
        expect_state(sender, JLSponge.FIN_ACKED)
        @test sender.bytes_in_flight == 0
        expect_no_seg(sender)
        tick!(sender, 1)
    end
end