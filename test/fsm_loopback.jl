@testset "fsm_loopback.jl" begin
    DEFAULT_CAPACITY = 65000
    TIMEOUT_DFLT = 1000
    NREPS = 64
    MAX_PAYLOAD_SIZE = 1460
    @testset "loop segments back into the same FSM" begin
        for i in 1:NREPS
            rx_offset = WrappingInt32(rand(UInt32))
            conn = fsm_in_established(rx_offset - 1, rx_offset - 1; cap=DEFAULT_CAPACITY)
            send_ack!(conn, rx_offset, rx_offset, 65000)
            d = rand(UInt8(0):UInt8(127), DEFAULT_CAPACITY) |> pointer |> unsafe_string
            sendoff = 0
            while sendoff < length(d)
                len = min(length(d) - sendoff, rand(UInt) % 8192) 
                len == 0 && continue
                write!(conn, @view(d[sendoff+1:sendoff+len]))
                tick!(conn, 1)
                @test bytes_in_flight(conn) == len
                @test conn.segments_out |> !isempty
                n_segments = (len - 1) ÷ MAX_PAYLOAD_SIZE + 1
                bytes_remaining = len
                for i in 1:n_segments
                    expected_size = min(bytes_remaining, MAX_PAYLOAD_SIZE)
                    seg = expect_seg(conn; payload_size = expected_size)
                    bytes_remaining -= expected_size
                    send_seg!(conn, seg)
                    tick!(conn, 1)
                end
                for i in 1:n_segments
                    seg = expect_seg(conn; ack=true, payload_size=0)
                    send_seg!(conn, seg)
                    tick!(conn, 1)
                end
                expect_no_seg(conn)
                @test bytes_in_flight(conn) == 0
                sendoff += len
            end
            expect_data!(conn, d)
        end
    end
end