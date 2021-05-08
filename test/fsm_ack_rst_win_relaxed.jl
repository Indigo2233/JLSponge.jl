
@testset "fsm_ack_rst_win_relaxed.jl" begin
    base_seq = WrappingInt32(1 << 31)
    DEFAULT_CAPACITY = 64000
    @testset "in ESTABLISHED, send unacceptable segments and ACKs" begin
        conn = fsm_in_established(base_seq - 1, base_seq - 1)
        
        send_ack!(conn, base_seq, base_seq - 1)
        expect_no_seg(conn)
        send_ack!(conn, base_seq, base_seq - 1)
        expect_no_seg(conn)
        
        send_byte!(conn, base_seq - 1, base_seq, Char(1))
        @test conn |> unassembled_bytes == 0
        expect_one_seg(conn, ackno=base_seq)

        send_byte!(conn, base_seq + DEFAULT_CAPACITY - 1, base_seq, Char(1))
        @test conn |> unassembled_bytes == 1
        expect_one_seg(conn, ackno=base_seq)
        expect_no_data(conn)        

        send_byte!(conn, base_seq, base_seq, Char(1))
        @test conn |> unassembled_bytes == 1
        expect_one_seg(conn, ackno=base_seq+1)
        expect_data!(conn)
        send_rst!(conn, base_seq + 1)
        expect_state(conn, JLSponge.RESET)
    end
end
