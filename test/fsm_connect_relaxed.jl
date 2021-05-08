@testset "fsm_active_close.jl" begin
    base_seq = WrappingInt32(1 << 31)
    DEFAULT_CAPACITY = 64000
    TIMEOUT_DFLT = 1000
    @testset "START -> SYN_SENT -> SYN/ACK -> ACK" begin
        conn = TCPConnection()
        connect!(conn)
        tick!(conn, 1)     
        seg1 = expect_one_seg(conn; ack=false, syn=true)
        expect_state(conn, JLSponge.SYN_SENT)

        isn = WrappingInt32(rand(UInt32))
        send_syn!(conn, isn, seg1.header.seqno + 1)
        tick!(conn, 1)
        expect_state(conn, JLSponge.ESTABLISHED)
        expect_one_seg(conn; ack=true, syn=false, ackno=isn+1)
        @test bytes_in_flight(conn) == 0
    end

    @testset "START -> SYN_SENT -> SYN/ACK -> ACK" begin
        conn = TCPConnection()
        connect!(conn)
        tick!(conn, 1)     
        seg1 = expect_one_seg(conn; ack=false, syn=true)
        seg_hdr = seg1.header
        expect_state(conn, JLSponge.SYN_SENT)

        isn = WrappingInt32(rand(UInt32))
        send_syn!(conn, isn)
        tick!(conn, 1)
        expect_one_seg(conn, syn=false, ack=true, ackno=isn + 1)

        expect_state(conn, JLSponge.SYN_RCVD) 
        send_ack!(conn, isn, seg_hdr.seqno + 1)
        tick!(conn, 1)
        expect_no_seg(conn)
        expect_state(conn, JLSponge.ESTABLISHED)
    end

    @testset "START -> SYN_SENT -> SYN/ACK -> ESTABLISHED" begin
        conn = TCPConnection()
        connect!(conn)
        tick!(conn, 1)     
        seg1 = expect_one_seg(conn; ack=false, syn=true)
        seg_hdr = seg1.header
        expect_state(conn, JLSponge.SYN_SENT)


        isn = WrappingInt32(rand(UInt32))
        send_syn!(conn, isn, seg_hdr.seqno + 1)
        tick!(conn, 1)
        expect_one_seg(conn; ack=true, ackno=isn + 1, syn=false)
        expect_state(conn, JLSponge.ESTABLISHED)
    end    
end
