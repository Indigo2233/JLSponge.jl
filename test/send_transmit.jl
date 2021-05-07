@testset "send_transmit.jl" begin
    @testset "Three short writes" begin
        isn = rand(UInt32(0):typemax(UInt32))

        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)

        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "ab")
        expect_seg(sender; data="ab", seqno=WrappingInt32(isn + 1))
        write_bytes!(sender, "cd")
        expect_seg(sender; data="cd", seqno=WrappingInt32(isn + 3))
        write_bytes!(sender, "abcd")
        expect_seg(sender; data="abcd", seqno=WrappingInt32(isn + 5))
        @test next_seqno(sender) == WrappingInt32(isn + 9)
        @test sender.bytes_in_flight == 8
        expect_state(sender, JLSponge.SYN_ACKED)
    end

    @testset "Many short writes, continuous acks" begin
        isn = rand(UInt32(0):typemax(UInt32))
    
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
    
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.SYN_ACKED)
        max_block_size = 10
        n_rounds = 10000
        bytes_sent = 0
    
        for i in 1:n_rounds
            block_size = rand(1:max_block_size)
            data = join(rand('a':'z', block_size))
            @test next_seqno(sender) == WrappingInt32(isn + bytes_sent + 1)
            write_bytes!(sender, data)
            bytes_sent += block_size
            @test sender.bytes_in_flight == block_size
            expect_seg(sender; seqno=WrappingInt32(isn + 1 + bytes_sent - block_size),
                       data=data)
            expect_no_seg(sender)
            ack_received_test(sender, WrappingInt32(isn + 1 + bytes_sent))
        end
    end
    @testset "Many short writes, ack at end" begin
        isn = rand(UInt32(0):typemax(UInt32))
    
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
    
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 65000)
        expect_state(sender, JLSponge.SYN_ACKED)
        max_block_size = 10
        n_rounds = 10000
        bytes_sent = 0
    
        for i in 1:n_rounds
            block_size = rand(1:max_block_size)
            data = join(rand('a':'z', block_size))
            @test next_seqno(sender) == WrappingInt32(isn + bytes_sent + 1)
            write_bytes!(sender, data)
            bytes_sent += block_size
            @test sender.bytes_in_flight == bytes_sent
            expect_seg(sender; seqno=WrappingInt32(isn + 1 + bytes_sent - block_size),
                       data=data)
            expect_no_seg(sender)
        end
        @test sender.bytes_in_flight == bytes_sent
        ack_received_test(sender, WrappingInt32(isn + 1 + bytes_sent))
        @test sender.bytes_in_flight == 0
    end
    
    @testset "Window filling" begin
        isn = rand(UInt32(0):typemax(UInt32))
    
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
    
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 3)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "01234567")
        @test sender.bytes_in_flight == 3
        expect_seg(sender; data="012")
        expect_no_seg(sender)
        @test next_seqno(sender) == WrappingInt32(isn + 1 + 3)
        ack_received_test(sender, WrappingInt32(isn + 1 + 3), 3)
        @test sender.bytes_in_flight == 3
        expect_seg(sender; data="345")
        expect_no_seg(sender)
        @test next_seqno(sender) == WrappingInt32(isn + 1 + 6)
        ack_received_test(sender, WrappingInt32(isn + 1 + 6), 3)
        @test sender.bytes_in_flight == 2
        expect_seg(sender; data="67")
        expect_no_seg(sender)
        @test next_seqno(sender) == WrappingInt32(isn + 1 + 8)
        ack_received_test(sender, WrappingInt32(isn + 1 + 8), 3)
        @test sender.bytes_in_flight == 0
        expect_no_seg(sender)
    end

    @testset "Window filling" begin
        isn = rand(UInt32(0):typemax(UInt32))
    
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
    
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 3)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "01")
        @test sender.bytes_in_flight == 2
        expect_seg(sender; data="01")
        expect_no_seg(sender)
        @test next_seqno(sender) == WrappingInt32(isn + 1 + 2)
        write_bytes!(sender, "23")
        @test sender.bytes_in_flight == 3
        expect_seg(sender; data="2")
        expect_no_seg(sender)
        @test next_seqno(sender) == WrappingInt32(isn + 1 + 3)    
    end    
end
