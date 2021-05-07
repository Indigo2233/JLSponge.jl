@testset "send_extra.jl" begin
    @testset "If already running, timer stays running when new segment sent" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "abc")
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        tick!(sender, rto - 5)
        expect_no_seg(sender)
        write_bytes!(sender, "def")
        expect_seg(sender, data="def", payload_size=3)
        tick!(sender, 6)
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        expect_no_seg(sender)
    end

    @testset "Retransmission still happens when expiration time not hit exactly" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "abc")
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        tick!(sender, rto - 5)
        expect_no_seg(sender)
        write_bytes!(sender, "def")
        expect_seg(sender, data="def", payload_size=3)
        tick!(sender, 200)
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        expect_no_seg(sender)
    end

    @testset "Timer restarts on ACK of new data" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "abc")
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        tick!(sender, rto - 1)
        expect_no_seg(sender)
        write_bytes!(sender, "def")
        expect_seg(sender, data="def", payload_size=3)
        ack_received_test(sender, WrappingInt32(isn + 4), 1000)
        tick!(sender, rto - 1)
        expect_no_seg(sender)
        tick!(sender, 2)
        expect_seg(sender, data="def", payload_size=3, seqno=WrappingInt32(isn + 4))
    end

    @testset "Timer doesn't restart without ACK of new data" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "abc")
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        tick!(sender, rto - 5)
        expect_no_seg(sender)
        write_bytes!(sender, "def")
        expect_seg(sender, data="def", payload_size=3, seqno=WrappingInt32(isn + 4))
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        tick!(sender, 6)
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        expect_no_seg(sender)
        tick!(sender, 2rto - 5)
        expect_no_seg(sender)
        tick!(sender, 8)
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        expect_no_seg(sender)
    end

    @testset "RTO resets on ACK of new data" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "abc")
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        tick!(sender, rto - 5)
        write_bytes!(sender, "def")
        expect_seg(sender, data="def", payload_size=3, seqno=WrappingInt32(isn + 4))
        write_bytes!(sender, "ghi")
        expect_seg(sender, data="ghi", payload_size=3, seqno=WrappingInt32(isn + 7))
        
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        tick!(sender, 6)
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        expect_no_seg(sender)
        tick!(sender, 2rto - 5)
        expect_no_seg(sender)
        tick!(sender, 5)
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        expect_no_seg(sender)

        tick!(sender, 4rto - 5)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 4), 1000)
        tick!(sender, rto - 1)
        expect_no_seg(sender)
        tick!(sender, 2)
        expect_seg(sender, data="def", payload_size=3, seqno=WrappingInt32(isn + 4))
        expect_no_seg(sender)
    end

    @testset "fill_window() correctly fills a big window" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        MAX_PAYLOAD_SIZE = 1460
        DEFAULT_CAPACITY = 64000
        nicechars = "abcdefghijklmnopqrstuvwxyz"
        bigstring = join(rand(nicechars, DEFAULT_CAPACITY))
        
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        write_bytes!(sender, bigstring)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), window_size)
        expect_state(sender, JLSponge.SYN_ACKED)
        i = UInt(0)
        while i + MAX_PAYLOAD_SIZE < min(length(bigstring), window_size)
            expected_size = min(MAX_PAYLOAD_SIZE, min(length(bigstring), window_size) - i)
            expect_seg(sender, no_flag=true, 
                payload_size=expected_size,
                data=@view(bigstring[i+1:i+expected_size]), 
                seqno=WrappingInt32(isn + 1 + i))
            i += MAX_PAYLOAD_SIZE
        end
    end    
    
    @testset "Retransmit a FIN-containing segment same as any other" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))

        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "abc", true)
        expect_seg(sender, data="abc", payload_size=3, fin=true, seqno=WrappingInt32(isn + 1))
        tick!(sender, rto - 1)
        expect_no_seg(sender)
        tick!(sender, 2)
        expect_seg(sender, data="abc", payload_size=3, fin=true, seqno=WrappingInt32(isn + 1))
    end
    
    @testset "Retransmit a FIN-only segment same as any other" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        expect_state(sender, JLSponge.SYN_ACKED)
        write_bytes!(sender, "abc")
        expect_seg(sender, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        sender_close(sender)
        expect_seg(sender, fin=true, payload_size=0, seqno=WrappingInt32(isn + 4))
        tick!(sender, rto - 1)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 4), 1000)
        tick!(sender, rto - 1)
        expect_no_seg(sender)
        tick!(sender, 2)
        expect_seg(sender, fin=true, payload_size=0, seqno=WrappingInt32(isn + 4))
        tick!(sender, 2rto - 5)
        expect_no_seg(sender)
        tick!(sender, 10)
        expect_seg(sender, fin=true, payload_size=0, seqno=WrappingInt32(isn + 4))
    end

    @testset "Don't add FIN if this would make the segment exceed the receiver's window" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        write_bytes!(sender, "abc", true)
        ack_received_test(sender, WrappingInt32(isn + 1), 3)
        expect_state(sender, JLSponge.SYN_ACKED)
    
        expect_seg(sender, no_flag=true, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        ack_received_test(sender, WrappingInt32(isn + 2), 2)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 3), 1)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 4), 1)
        expect_seg(sender, fin=true, payload_size=0, seqno=WrappingInt32(isn + 4))

    end

    @testset "Don't send FIN by itself if the window is full" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)
    
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        write_bytes!(sender, "abc")
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1), 3)
        expect_state(sender, JLSponge.SYN_ACKED)
    
        expect_seg(sender, no_flag=true, data="abc", payload_size=3, seqno=WrappingInt32(isn + 1))
        sender_close(sender)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 2), 2)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 3), 1)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 4), 1)
        expect_seg(sender, fin=true, payload_size=0, seqno=WrappingInt32(isn + 4))
    
    end

    @testset "MAX_PAYLOAD_SIZE limits payload only" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        MAX_PAYLOAD_SIZE = 1460
        nicechars = "abcdefghijklmnopqrstuvwxyz"
        bigstring = join(rand(nicechars, MAX_PAYLOAD_SIZE))
        
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)
    
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        write_bytes!(sender, bigstring, true)
        ack_received_test(sender, WrappingInt32(isn + 1), 40000)
        expect_seg(sender, data=bigstring, fin=true, payload_size=MAX_PAYLOAD_SIZE, seqno=WrappingInt32(isn + 1))
        expect_state(sender, JLSponge.FIN_SENT)
        ack_received_test(sender, WrappingInt32(isn + 2 + MAX_PAYLOAD_SIZE))
        expect_state(sender, JLSponge.FIN_ACKED)
        
    end

    @testset "When filling window, treat a '0' window size as equal to '1' but don't back off RTO" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)

        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        
        write_bytes!(sender, "abc")
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1), 0)
        expect_state(sender, JLSponge.SYN_ACKED)
        expect_seg(sender, data="a", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 1))
        sender_close(sender)
        expect_no_seg(sender)

        for i in 1:5
            tick!(sender, rto - 1)
            expect_no_seg(sender)
            tick!(sender, 1)      
            expect_seg(sender, data="a", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 1))
        end
        ack_received_test(sender, WrappingInt32(isn + 2), 0)
        expect_seg(sender, data="b", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 2))

        for i in 1:5
            tick!(sender, rto - 1)
            expect_no_seg(sender)
            tick!(sender, 1)
            expect_seg(sender, data="b", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 2))
        end

        ack_received_test(sender, WrappingInt32(isn + 3), 0)
        expect_seg(sender, data="c", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 3))
        for i in 1:5
            tick!(sender, rto - 1)
            expect_no_seg(sender)
            tick!(sender, 1)
            expect_seg(sender, data="c", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 3))
        end

        ack_received_test(sender, WrappingInt32(isn + 4), 0)
        expect_seg(sender, data="", fin=true, payload_size=0, seqno=WrappingInt32(isn + 4))
        for i in 1:5
            tick!(sender, rto - 1)
            expect_no_seg(sender)
            tick!(sender, 1)
            expect_seg(sender, data="", fin=true, payload_size=0, seqno=WrappingInt32(isn + 4))
        end
    end

    @testset "Unlike a zero-size window, a full window of nonzero size should be respected" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)
    
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        
        write_bytes!(sender, "abc")
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1), 1)
        expect_state(sender, JLSponge.SYN_ACKED)
        expect_seg(sender, data="a", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 1))
        
        tick!(sender, rto - 1)
        expect_no_seg(sender)
        tick!(sender, 1)
        expect_seg(sender, data="a", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 1))
        
        sender_close(sender)
        tick!(sender, 2rto - 1)
        expect_no_seg(sender)
        tick!(sender, 1)
        expect_seg(sender, data="a", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 1))
        
        tick!(sender, 4rto - 1)
        expect_no_seg(sender)
        tick!(sender, 1)
        expect_seg(sender, data="a", no_flag=true, payload_size=1, seqno=WrappingInt32(isn + 1))
        
        ack_received_test(sender, WrappingInt32(isn + 2), 3)
        expect_seg(sender, data="bc", fin=true, payload_size=2, seqno=WrappingInt32(isn + 2))
    end

    @testset "Repeated ACKs and outdated ACKs are harmless" begin 
        isn = rand(UInt32(0):typemax(UInt32))
        rto = rand(UInt16(30):UInt16(10000))
        window_size = rand(UInt16(50000):UInt16(63000))
        
        sender = TCPSender(fixed_isn=WrappingInt32(isn), retx_timeout = rto)
        fill_window!(sender)
    
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        expect_state(sender, JLSponge.SYN_ACKED)
        
        write_bytes!(sender, "abcdefg")
        expect_seg(sender, data="abcdefg", no_flag=true, payload_size=7, seqno=WrappingInt32(isn + 1))
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        expect_no_seg(sender)
        write_bytes!(sender, "ijkl", true)
        expect_seg(sender, data="ijkl", fin=true, payload_size=4, seqno=WrappingInt32(isn + 8))
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        ack_received_test(sender, WrappingInt32(isn + 8), 1000)
        ack_received_test(sender, WrappingInt32(isn + 12), 1000)
        ack_received_test(sender, WrappingInt32(isn + 12), 1000)
        ack_received_test(sender, WrappingInt32(isn + 12), 1000)
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        tick!(sender, 5rto)
        expect_seg(sender, data="ijkl", fin=true, payload_size=4, seqno=WrappingInt32(isn + 8))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 13), 1000)
        ack_received_test(sender, WrappingInt32(isn + 1), 1000)
        tick!(sender, 5rto)
        expect_no_seg(sender)
        
        expect_state(sender, JLSponge.FIN_ACKED)
    end    
end


