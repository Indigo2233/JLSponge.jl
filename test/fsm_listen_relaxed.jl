@testset "fsm_active_close.jl" begin
    base_seq = WrappingInt32(1 << 31)
    DEFAULT_CAPACITY = 64000
    TIMEOUT_DFLT = 1000
    @testset "start in TIME_WAIT, timeout" begin
        conn = TCPConnection()
        #Listen will do nothing
        expect_state(conn, JLSponge.LISTEN)
        tick!(conn, 1)     
        expect_state(conn, JLSponge.LISTEN)
        
        send_syn!(conn, WrappingInt32(0))
        tick!(conn, 1)
        seg = expect_one_seg(conn; ack=true, syn=true, ackno=WrappingInt32(1))
        expect_state(conn, JLSponge.SYN_RCVD)
        send_ack!(conn, WrappingInt32(1), seg.header.seqno + 1)
        tick!(conn, 1)
        expect_no_seg(conn)

        expect_state(conn, JLSponge.ESTABLISHED)
    end
end