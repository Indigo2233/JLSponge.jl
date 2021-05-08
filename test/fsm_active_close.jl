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
end
