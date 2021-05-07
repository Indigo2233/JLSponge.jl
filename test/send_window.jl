@testset "send_window.jl" begin
    @testset "Initial receiver advertised window is respected" begin
        isn = rand(UInt32(0):typemax(UInt32))
        
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
    
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 4)
        expect_no_seg(sender)
        write_bytes!(sender, "abcdefg")
        expect_seg(sender; no_flag=true, data = "abcd")    
        expect_no_seg(sender)    
    end

    @testset "Immediate window is respected" begin
        isn = rand(UInt32(0):typemax(UInt32))
        
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
    
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 6)
        expect_no_seg(sender)
        write_bytes!(sender, "abcdefg")
        expect_seg(sender; no_flag=true, data = "abcdef")    
        expect_no_seg(sender)    
    end
    @testset "Window" begin
        N_REPS = 1000
        MIN_WIN = 5
        MAX_WIN = 100
        for i in 1:N_REPS
    
            isn = rand(UInt32(0):typemax(UInt32))
            len = rand(MIN_WIN:MAX_WIN)
    
            sender = TCPSender(; fixed_isn=WrappingInt32(isn))
            fill_window!(sender)
            expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
            ack_received_test(sender, WrappingInt32(isn + 1), len)
            expect_no_seg(sender)
            write_bytes!(sender, "a"^(2N_REPS))
            expect_seg(sender; payload_size=len, no_flag=true)
            expect_no_seg(sender)
        end
    end
    @testset "Window growth is exploited" begin
        isn = rand(UInt32(0):typemax(UInt32))
    
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 4)
        expect_no_seg(sender)
        write_bytes!(sender, "0123456789")
        expect_seg(sender; no_flag=true, data="0123")
        ack_received_test(sender, WrappingInt32(isn+5), 5)
        expect_seg(sender; no_flag=true, data="45678")
        expect_no_seg(sender)
    end
    @testset "FIN flag occupies space in window" begin
        isn = rand(UInt32(0):typemax(UInt32))
    
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 7)
        expect_no_seg(sender)
        write_bytes!(sender, "1234567")
        sender_close(sender)
        expect_seg(sender; no_flag=true, data="1234567")
        expect_no_seg(sender)
    
        ack_received_test(sender, WrappingInt32(isn+8), 1)
        expect_seg(sender; fin=true, data="")
        expect_no_seg(sender)
    end
    @testset "FIN flag occupies space in window (part II)" begin
        isn = rand(UInt32(0):typemax(UInt32))
    
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 7)
        expect_no_seg(sender)
        write_bytes!(sender, "1234567")
        sender_close(sender)
        expect_seg(sender; no_flag=true, data="1234567")
        expect_no_seg(sender)
    
        ack_received_test(sender, WrappingInt32(isn+1), 8)
        expect_seg(sender; fin=true, data="")
        expect_no_seg(sender)
    end
    @testset "Piggyback FIN in segment when space is available" begin
        isn = rand(UInt32(0):typemax(UInt32))
    
        sender = TCPSender(; fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender; no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 3)
        expect_no_seg(sender)
        write_bytes!(sender, "1234567")
        sender_close(sender)
        expect_seg(sender; no_flag=true, data="123")
        expect_no_seg(sender)
    
        ack_received_test(sender, WrappingInt32(isn+1), 8)
        expect_seg(sender; fin=true, data="4567")
        expect_no_seg(sender)
    end
        
end