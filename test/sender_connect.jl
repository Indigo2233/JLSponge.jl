@testset "sender_connect.jl" begin
    @testset "SYN sent test" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)

        expect_state(sender, JLSponge.SYN_SENT)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        @test sender.bytes_in_flight == 1
    end

    @testset "SYN acked test" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)

        expect_state(sender, JLSponge.SYN_SENT)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        @test sender.bytes_in_flight == 1
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.SYN_ACKED)
        @test sender.bytes_in_flight == 0
        expect_no_seg(sender)
    end

    @testset "SYN -> wrong ack test" begin
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)

        expect_state(sender, JLSponge.SYN_SENT)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        @test sender.bytes_in_flight == 1
        ack_received_test(sender, WrappingInt32(isn))
        expect_state(sender, JLSponge.SYN_SENT)
        @test sender.bytes_in_flight == 1
        expect_no_seg(sender)
    end

    @testset "SYN acked, data" begin
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)

        expect_state(sender, JLSponge.SYN_SENT)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        @test sender.bytes_in_flight == 1
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.SYN_ACKED)
        @test sender.bytes_in_flight == 0
        expect_no_seg(sender)
        write_bytes!(sender, "abcdefgh")
        tick!(sender, 1)
        expect_state(sender, JLSponge.SYN_ACKED)
        expect_seg(sender, data="abcdefgh", seqno=WrappingInt32(isn + 1))
        @test sender.bytes_in_flight == 8
        ack_received_test(sender, WrappingInt32(isn + 9))
        expect_state(sender, JLSponge.SYN_ACKED)
        @test sender.bytes_in_flight == 0
        expect_no_seg(sender)
        @test next_seqno(sender) == WrappingInt32(isn + 9)
    end
end