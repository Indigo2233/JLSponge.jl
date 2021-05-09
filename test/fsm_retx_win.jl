@testset "fsm_retx_win.jl" begin
    DEFAULT_CAPACITY = 65000
    TIMEOUT_DFLT = 1000
    NREPS = 64
    MAX_PAYLOAD_SIZE = 1460
    MAX_RETX_ATTEMPTS = 8
    @testset "multiple segments with intervening ack" begin
        tx_ackno = WrappingInt32(rand(UInt32))
        conn = fsm_in_established(tx_ackno - 1, tx_ackno - 1; cap=DEFAULT_CAPACITY)
        d1 = "asdf"
        d2 = "qwer"
        
        write!(conn, d1)
        tick!(conn, 1)
        tick!(conn, 20)
        write!(conn, d2)
        tick!(conn, 1)
        @test conn.segments_out |> !isempty
        expect_seg(conn; data=d1, ack=true, payload_size=length(d1))
        expect_one_seg(conn; data=d2, ack=true, payload_size=length(d1))
        tick!(conn, TIMEOUT_DFLT - 23)
        expect_no_seg(conn)

        tick!(conn, 4)
        expect_one_seg(conn; data=d1, ack=true, payload_size=length(d1))
        tick!(conn, 2TIMEOUT_DFLT - 2)
        expect_no_seg(conn)
        send_ack!(conn, tx_ackno, tx_ackno + 4)
        tick!(conn, TIMEOUT_DFLT - 2)
        expect_no_seg(conn)
        tick!(conn, 3)
        expect_one_seg(conn; data=d2, ack=true, payload_size=length(d1))
    end

    @testset "multiple segments without intervening ack" begin
        tx_ackno = WrappingInt32(rand(UInt32))
        conn = fsm_in_established(tx_ackno - 1, tx_ackno - 1; cap=DEFAULT_CAPACITY)
        d1 = "asdf"
        d2 = "qwer"
        
        write!(conn, d1)
        tick!(conn, 1)
        tick!(conn, 20)
        write!(conn, d2)
        tick!(conn, 1)
        
        @test conn.segments_out |> !isempty
        expect_seg(conn; data=d1, ack=true, payload_size=length(d1))
        expect_one_seg(conn; data=d2, ack=true, payload_size=length(d1))
        tick!(conn, TIMEOUT_DFLT - 23)
        expect_no_seg(conn)

        tick!(conn, 4)
        expect_one_seg(conn; data=d1, ack=true, payload_size=length(d1))
        tick!(conn, 2TIMEOUT_DFLT - 2)
        expect_no_seg(conn)
        tick!(conn, 3)
        expect_one_seg(conn; data=d1, ack=true, payload_size=length(d1))
    end

    @testset "check that ACK of new data resets exponential backoff and restarts timer" begin
        backoff_test = function (num_backoffs::Int)
            tx_ackno = WrappingInt32(rand(UInt32))
            conn = fsm_in_established(tx_ackno - 1, tx_ackno - 1; cap=DEFAULT_CAPACITY)
            d1 = "asdf"
            d2 = "qwer"
            
            write!(conn, d1)
            tick!(conn, 1)
            tick!(conn, 20)
            write!(conn, d2)
            tick!(conn, 1)

            @test conn.segments_out |> !isempty
            expect_seg(conn; data=d1, ack=true, payload_size=length(d1))
            expect_one_seg(conn; data=d2, ack=true, payload_size=length(d1))
            tick!(conn, TIMEOUT_DFLT - 23)
            expect_no_seg(conn)
    
            tick!(conn, 4)
            expect_one_seg(conn; data=d1, ack=true, payload_size=length(d1))
            for i in 1:num_backoffs-1
                tick!(conn, (TIMEOUT_DFLT << i) - i)
                expect_no_seg(conn)
                tick!(conn, i)
                expect_one_seg(conn; ack=true, data=d1, payload_size=length(data))
            end
            send_ack!(conn, tx_ackno, tx_ackno + 4)
            tick!(conn, TIMEOUT_DFLT - 2)
            expect_no_seg(conn)
            tick!(conn, 3)
            expect_one_seg(conn; ack=true, data=d2, payload_size=length(data))
        end
        for i in 1:MAX_RETX_ATTEMPTS
            backoff_test(i - 1)
        end
    end
end