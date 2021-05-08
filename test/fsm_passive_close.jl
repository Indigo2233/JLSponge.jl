@testset "fsm_loopback.jl" begin
    TIMEOUT_DFLT = 1000
    @testset "start in LAST_ACK, ack" begin
        conn = fsm_in_last_ack()
        tick!(conn, 4TIMEOUT_DFLT)
        expect_state(conn, JLSponge.LAST_ACK)
        send_ack!(conn, WrappingInt32(2), WrappingInt32(2))
        tick!(conn, 1)
        expect_state(conn, JLSponge.CLOSED)
    end

    @testset "start in CLOSE_WAIT, close(), throw away first FIN, ack re-tx FIN" begin
        conn = fsm_in_close_wait()
        tick!(conn, 4TIMEOUT_DFLT)
        expect_state(conn, JLSponge.CLOSE_WAIT)
        end_input_stream!(conn)
        tick!(conn, 1)
        expect_state(conn, JLSponge.LAST_ACK)
        
        seg1 = expect_one_seg(conn; fin=true)

        tick!(conn, TIMEOUT_DFLT - 2)
        expect_no_seg(conn)
        tick!(conn, 2)

        seg2 = expect_one_seg(conn; fin=true, seqno=seg1.header.seqno)

        rx_seqno = WrappingInt32(2)
        ack_expect = rx_seqno
        send_ack!(conn, ack_expect, seg2.header.seqno - 1)
        expect_state(conn, JLSponge.LAST_ACK)

        send_ack!(conn, ack_expect, seg2.header.seqno + 1)
        
        tick!(conn, 1)
        expect_state(conn, JLSponge.CLOSED)
    end
   
    @testset "start in ESTABLISHED, send FIN, recv ACK, check for CLOSE_WAIT" begin
        conn = fsm_in_established()
        tick!(conn, 4TIMEOUT_DFLT)
        expect_state(conn, JLSponge.ESTABLISHED)

        rx_seqno = WrappingInt32(1)
        ack_expect = rx_seqno + 1
        send_fin!(conn, rx_seqno, WrappingInt32(0))
        tick!(conn, 1)

        expect_one_seg(conn, ack=true, ackno=ack_expect)
        expect_state(conn, JLSponge.CLOSE_WAIT)

        send_fin!(conn, rx_seqno, WrappingInt32(0))
        tick!(conn, 1)

        expect_one_seg(conn; ack=true, ackno=ack_expect)

        expect_state(conn, JLSponge.CLOSE_WAIT)

        tick!(conn, 1)
        end_input_stream!(conn)
        tick!(conn, 1)
        expect_state(conn, JLSponge.LAST_ACK)
        seg3 = expect_one_seg(conn; fin=true)
        send_ack!(conn, ack_expect, seg3.header.seqno + 1)        
        tick!(conn, 1)
        expect_state(conn, JLSponge.CLOSED)
    end
end