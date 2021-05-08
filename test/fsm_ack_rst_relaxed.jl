@testset "fsm_ack_rst_relaxed.jl" begin    
    function ack_listen_test(seqno::WrappingInt32, ackno::WrappingInt32; 
        cap::Int=64000, 
        retx_timeout::UInt16=UInt16(1000), 
        fixed_isn=nothing)
        conn = fsm_in_listen(;cap, retx_timeout, fixed_isn)
        send_ack!(conn, seqno, ackno)
        expect_state(conn, JLSponge.LISTEN)
        expect_no_seg(conn)
    end

    function ack_rst_syn_sent_test(base_seq::WrappingInt32,
        seqno::WrappingInt32,
        ackno::WrappingInt32;
        cap::Int=64000, 
        retx_timeout::UInt16=UInt16(1000), 
        fixed_isn=nothing)
        conn = fsm_in_syn_sent(base_seq)
        send_ack!(conn, seqno, ackno)
        expect_state(conn, JLSponge.SYN_SENT)
        expect_no_seg(conn)
    end

    base_seq = WrappingInt32(1 << 31)
    DEFAULT_CAPACITY = 64000
    @testset "in ESTABLISHED, send unacceptable segments and ACKs" begin
        conn = fsm_in_established(base_seq - 1, base_seq - 1)
        send_ack!(conn, base_seq, base_seq)
        expect_no_seg(conn)
        send_ack!(conn, base_seq, base_seq - 1)
        expect_no_seg(conn)
        
        send_byte!(conn, base_seq - 1, base_seq, Char(1))
    
        @test conn |> unassembled_bytes == 0
        expect_one_seg(conn; ack=true, ackno=base_seq)
        send_byte!(conn, base_seq + DEFAULT_CAPACITY, base_seq, Char(1))
        @test conn |> unassembled_bytes == 0
        expect_one_seg(conn; ack=true, ackno=base_seq)
        send_byte!(conn, base_seq, base_seq, Char(1))
        expect_data!(conn)
        expect_one_seg(conn; ack=true, ackno=base_seq+1)
        send_rst!(conn, base_seq+1)
        expect_state(conn, JLSponge.RESET)
    end
    @testset "in LISTEN, send RSTs" begin
        conn = fsm_in_listen()
        send_rst!(conn, base_seq)
        send_rst!(conn, base_seq - 1)
        send_rst!(conn, base_seq - DEFAULT_CAPACITY)
        expect_no_seg(conn)
    end
    @testset "ACKs in LISTEN" begin
       ack_listen_test(base_seq, base_seq)
       ack_listen_test(base_seq - 1, base_seq)
       ack_listen_test(base_seq, base_seq - 1)
       ack_listen_test(base_seq - 1, base_seq)
       ack_listen_test(base_seq - 1, base_seq - 1)
       ack_listen_test(base_seq + DEFAULT_CAPACITY, base_seq)
       ack_listen_test(base_seq, base_seq + DEFAULT_CAPACITY)
       ack_listen_test(base_seq + DEFAULT_CAPACITY, base_seq)
       ack_listen_test(base_seq + DEFAULT_CAPACITY, base_seq + DEFAULT_CAPACITY)
    end

    @testset "ACK and RST in SYN_SENT" begin
        conn = fsm_in_syn_sent(base_seq)
        send_rst!(conn, base_seq + 1)
        expect_state(conn, JLSponge.RESET)
        expect_no_seg(conn)
    end

    @testset "ack/rst in SYN_SENT" begin
        ack_rst_syn_sent_test(base_seq, base_seq, base_seq)
        ack_rst_syn_sent_test(base_seq, base_seq, base_seq + 2)
    end
end

"""

"""