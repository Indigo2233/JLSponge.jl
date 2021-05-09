import Random.shuffle!
@testset "fsm_loopback_win.jl" begin
    DEFAULT_CAPACITY = 65000
    TIMEOUT_DFLT = 1000
    NREPS = 32
    MAX_PAYLOAD_SIZE = 1460
    @testset "loop segments back in a different order" begin
        for i in 0:NREPS
            rx_offset = WrappingInt32(rand(UInt32))
            conn = fsm_in_established(rx_offset - 1, rx_offset - 1; cap=DEFAULT_CAPACITY)
            send_ack!(conn, rx_offset, rx_offset, 65000)
            d = rand(UInt8(1):UInt8(127), DEFAULT_CAPACITY) |> pointer |> unsafe_string
            sendoff = 0
            segs = TCPSegment[] 
            sendoff = 0
            println(length(d))
            while sendoff < length(d)
                len = min(length(d) - sendoff, rand(UInt) % 8192) 
                len == 0 && continue
                write!(conn, @view(d[sendoff+1:sendoff+len]))
                tick!(conn, 1)
                @test bytes_in_flight(conn) == sendoff + len
                @test conn.segments_out |> !isempty
                while conn.segments_out |> !isempty
                    push!(segs, expect_seg(conn))
                end
                sendoff += len
            end
            println(length(segs))
            seg_idx = collect(1:length(segs))
            shuffle!(seg_idx)
            acks = TCPSegment[]
            for idx in seg_idx
                send_seg!(conn, segs[idx])
                tick!(conn, 1)
                s = expect_one_seg(conn; ack=true)
                push!(acks, s)
                expect_no_seg(conn)
            end
            send_seg!(conn, acks[end])
            expect_no_seg(conn)
            expect_data!(conn, d)
        end
    end
end