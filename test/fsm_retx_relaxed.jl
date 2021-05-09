@testset "fsm_retx_relaxed.jl" begin
    DEFAULT_CAPACITY = 65000
    TIMEOUT_DFLT = 1000
    NREPS = 64
    MAX_PAYLOAD_SIZE = 1460
    MAX_RETX_ATTEMPTS = 8
    @testset "single segment re-transmit" begin
        tx_ackno = WrappingInt32(rand(UInt32))
        conn = fsm_in_established(tx_ackno - 1, tx_ackno - 1; cap=DEFAULT_CAPACITY)
        data = "asdf"
        write!(conn, data)
        tick!(conn, 1)
        expect_one_seg(conn; ack=true, data, payload_size=length(data))
        tick!(conn, TIMEOUT_DFLT - 2)
        
        expect_no_seg(conn)
        tick!(conn, 2)
        expect_one_seg(conn; ack=true, data, payload_size=length(data))
        
        tick!(conn, 10TIMEOUT_DFLT + 100)
        expect_one_seg(conn; ack=true, data, payload_size=length(data))
        
        for i in 2:MAX_RETX_ATTEMPTS-1
            tick!(conn, (TIMEOUT_DFLT << i) - i)
            expect_no_seg(conn)
            tick!(conn, i)
            expect_one_seg(conn; ack=true, data, payload_size=length(data))    
        end
        expect_state(conn, JLSponge.ESTABLISHED)
        tick!(conn, (TIMEOUT_DFLT << MAX_RETX_ATTEMPTS) + 1)
        expect_state(conn, JLSponge.RESET)
        expect_one_seg(conn; rst=true)
    end
end