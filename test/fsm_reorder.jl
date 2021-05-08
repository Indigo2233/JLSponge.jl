import Random.shuffle!
@testset "fsm_reorder.jl" begin
    DEFAULT_CAPACITY = 65000
    TIMEOUT_DFLT = 1000
    NREPS = 64
    MAX_PAYLOAD_SIZE = 1460
    @testset "non-overlapping out-of-order segments" begin
        for i in 1:NREPS
            rx_isn, tx_isn = WrappingInt32(rand(UInt32)), WrappingInt32(rand(UInt32))
            conn = fsm_in_established(tx_isn, rx_isn; cap=DEFAULT_CAPACITY)
            seq_size = Tuple{UInt, UInt}[]
            datalen = 0
            while datalen < DEFAULT_CAPACITY
                sz = min(rand(UInt) % (MAX_PAYLOAD_SIZE - 1) + 1, DEFAULT_CAPACITY - datalen)
                push!(seq_size, (datalen, sz))
                datalen += sz
            end
            shuffle!(seq_size)
            d = rand('a':'z', datalen) |> join
            min_expect_ackno = rx_isn + 1
            max_expect_ackno = rx_isn + 1
            for (off, sz) in seq_size
                send_data!(conn, rx_isn + 1 + off, tx_isn + 1, @view(d[1+off:off+sz]))     
                (off == min_expect_ackno.val) && (min_expect_ackno = min_expect_ackno + sz)
                max_expect_ackno = max_expect_ackno + sz
                seg = expect_seg(conn; ack=true)
                seg_hdr = seg.header
                @test seg_hdr.ackno.val >= min_expect_ackno.val 
                @test seg_hdr.ackno.val <= max_expect_ackno.val 
            end
            tick!(conn, 1)
            expect_data!(conn, d)
        end
    end

    @testset "overlapping out-of-order segments" begin
        for i in 1:NREPS
            rx_isn, tx_isn = WrappingInt32(rand(UInt32)), WrappingInt32(rand(UInt32))
            conn = fsm_in_established(tx_isn, rx_isn; cap=DEFAULT_CAPACITY)
            seq_size = Tuple{UInt, UInt}[]
            datalen = 0
            while datalen < DEFAULT_CAPACITY
                sz = min(rand(UInt) % (MAX_PAYLOAD_SIZE - 1) + 1, DEFAULT_CAPACITY - datalen)
                rem = MAX_PAYLOAD_SIZE - sz
                offs = UInt(0)
                if rem == 0
                    offs = 0
                elseif rem == 1
                    offs = min(UInt(1), datalen)
                else
                    offs = min(datalen, rem, 1 + rand(UInt) % (rem - 1))
                end
                @test sz + offs <= MAX_PAYLOAD_SIZE
                push!(seq_size, (datalen - offs, sz + offs))
                datalen += sz
            end
            @test datalen <= DEFAULT_CAPACITY
            shuffle!(seq_size)
            d = rand('a':'z', datalen) |> join
            min_expect_ackno = rx_isn + 1
            max_expect_ackno = rx_isn + 1
            for (off, sz) in seq_size
                send_data!(conn, rx_isn + 1 + off, tx_isn + 1, @view(d[1+off:off+sz]))     
                (off <= min_expect_ackno.val && off + sz > min_expect_ackno.val) &&
                    (min_expect_ackno = WrappingInt32(sz + off))
                max_expect_ackno = max_expect_ackno + sz

                seg = expect_seg(conn; ack=true)
                seg_hdr = seg.header
                @test seg_hdr.ackno.val >= min_expect_ackno.val 
                @test seg_hdr.ackno.val <= max_expect_ackno.val 
            end
            tick!(conn, 1)
            expect_data!(conn, d)
        end
    end

end