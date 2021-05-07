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
    expect_state(conn, JLSponge.SENT)
    expect_no_seg(conn)
end

@testset "fsm_ack_rst_relaxed.jl" begin
    base_seq = WrappingInt32(1 << 31)
    DEFAULT_CAPACITY = 64000
    @testset begin
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
end

"""
test_1.send_byte(base_seq - 1, base_seq, 1);

test_1.execute(ExpectUnassembledBytes{0}, "test 1 failed: seg queued on early seqno");

test_1.execute(ExpectOneSegment{}.with_ack(true).with_ackno(base_seq), "test 1 failed: bad ACK");

// segment out of the window---should get an ACK
test_1.send_byte(base_seq + cfg.recv_capacity, base_seq, 1);

test_1.execute(ExpectUnassembledBytes{0}, "test 1 failed: seg queued on late seqno");
test_1.execute(ExpectOneSegment{}.with_ack(true).with_ackno(base_seq),
               "test 1 failed: bad ACK on late seqno");

// packet next byte in the window - ack should advance and data should be readable
test_1.send_byte(base_seq, base_seq, 1);

test_1.execute(ExpectData{}, "test 1 failed: pkt not processed on next seqno");

test_1.execute(ExpectOneSegment{}.with_ack(true).with_ackno(base_seq + 1), "test 1 failed: bad ACK");

test_1.send_rst(base_seq + 1);
test_1.execute(ExpectState{State::RESET});
"""