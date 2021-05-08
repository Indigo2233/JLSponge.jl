@testset "fsm_active_close.jl" begin
    base_seq = WrappingInt32(1 << 31)
    DEFAULT_CAPACITY = 64000
    TIMEOUT_DFLT = 1000
    @testset "start in TIME_WAIT, timeout" begin
        conn = fsm_in_time_wait()
        tick!(conn, 10TIMEOUT_DFLT - 1)
        expect_state(conn, JLSponge.TIME_WAIT)
        tick!(conn, 1)
        expect_notin_state(conn, JLSponge.TIME_WAIT)
        tick!(conn, 10TIMEOUT_DFLT)
        expect_state(conn, JLSponge.CLOSED)
    end

    @testset "start in CLOSING, send ack, time out" begin
        conn = fsm_in_closing()
        tick!(conn, 4TIMEOUT_DFLT)
        expect_one_seg(conn, fin=true)
        expect_state(conn, JLSponge.CLOSING)
        send_ack!(conn, WrappingInt32(2), WrappingInt32(2))
        expect_no_seg(conn)
        expect_state(conn, JLSponge.TIME_WAIT)
        
        tick!(conn, 10TIMEOUT_DFLT - 1)
        expect_state(conn, JLSponge.TIME_WAIT)
        tick!(conn, 2)
        expect_state(conn, JLSponge.CLOSED)
    end
    
    @testset "start in FIN_WAIT_2, send FIN, time out" begin
        conn = fsm_in_fin_wait_2()
        tick!(conn, 4TIMEOUT_DFLT)
        expect_state(conn, JLSponge.FIN_WAIT_2)

        rx_seqno = WrappingInt32(1)
        send_fin!(conn, rx_seqno, WrappingInt32(2))

        tick!(conn, 1)
        expect_one_seg(conn; ack=true, ackno=rx_seqno + 1)
        expect_state(conn, JLSponge.TIME_WAIT)

        tick!(conn, 10TIMEOUT_DFLT)
        expect_state(conn, JLSponge.CLOSED)
    end

    @testset "start in FIN_WAIT_1, ack, FIN, time out" begin
        conn = fsm_in_fin_wait_1()
        tick!(conn, 4TIMEOUT_DFLT)
        expect_one_seg(conn; fin=true)
        rx_seqno = WrappingInt32(1)
        send_ack!(conn, rx_seqno, WrappingInt32(2))
        tick!(conn, 5)
        send_fin!(conn, rx_seqno, WrappingInt32(2))
        ack_expect = rx_seqno + 1
        tick!(conn, 1)
        expect_one_seg(conn; no_flag=true, ack=true, ackno=ack_expect)
        tick!(conn, 10TIMEOUT_DFLT)
        expect_state(conn, JLSponge.CLOSED)
    end

    @testset "start in FIN_WAIT_1, ack, FIN, FIN again, time out" begin
        conn = fsm_in_fin_wait_1()

        rx_seqno = WrappingInt32(1)
        send_ack!(conn, rx_seqno, WrappingInt32(2))
        expect_state(conn, JLSponge.FIN_WAIT_2)
        tick!(conn, 5)
        send_fin!(conn, rx_seqno, WrappingInt32(2))
        expect_state(conn, JLSponge.TIME_WAIT)
        @test conn.time_since_last_segment_received == 0
        ack_expect = rx_seqno + 1
        tick!(conn, 1)
        @test conn.time_since_last_segment_received == 1
        expect_one_seg(conn, no_flag=true, ack=true, ackno=ack_expect)
        tick!(conn, 10TIMEOUT_DFLT - 10)
        @test conn.time_since_last_segment_received == 10TIMEOUT_DFLT - 9
        send_fin!(conn, rx_seqno, WrappingInt32(2))
        @test conn.time_since_last_segment_received == 0
        tick!(conn, 1)
        expect_one_seg(conn, ack=true, ackno=ack_expect)
        expect_state(conn, JLSponge.TIME_WAIT)

        tick!(conn, 10TIMEOUT_DFLT - 10)
        @test conn.time_since_last_segment_received == 10TIMEOUT_DFLT - 9
        expect_no_seg(conn)
        tick!(conn, 10)
        expect_state(conn, JLSponge.CLOSED)
    end

    @testset "start in FIN_WAIT_1, ack, FIN, FIN again, time out" begin
        conn = fsm_in_established()
        end_input_stream!(conn)

        tick!(conn, 1)
        seg1 = expect_one_seg(conn; fin=true)
        seg1_hdr = seg1.header
        tick!(conn, TIMEOUT_DFLT - 2)
        expect_no_seg(conn)
        tick!(conn, 2)
        seg2 = expect_one_seg(conn; fin=true, seqno=seg1_hdr.seqno)
        seg2_hdr = seg2.header
        rx_seqno = WrappingInt32(1)
        send_fin!(conn, rx_seqno, WrappingInt32(0))
        ack_expect = rx_seqno + 1
        tick!(conn, 1)
        
        expect_state(conn, JLSponge.CLOSING)
        expect_one_seg(conn, ack=true, ackno=ack_expect)

        send_ack!(conn, ack_expect, seg2_hdr.seqno + 1)
        tick!(conn, 1)
        expect_state(conn, JLSponge.TIME_WAIT)
        
        tick!(conn, 10TIMEOUT_DFLT)
        expect_state(conn, JLSponge.CLOSED)
    end 
end