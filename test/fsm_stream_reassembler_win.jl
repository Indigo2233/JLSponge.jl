import Random.shuffle!
@testset "fsm_stream_reassembler_win.jl" begin
    NREPS = 32
    NSEGS = 128
    MAX_SEG_LEN = 2048
    for i in 1:NREPS
        buf = StreamReassembler(NSEGS * MAX_SEG_LEN)
        seq_size = Tuple{Int, Int}[]
        offset = 0
        for i in 1:NSEGS
            sz = 1 + rand(UInt) % (MAX_SEG_LEN - 1)
            offs = min(offset, 1 + rand(UInt) % 1023)
            push!(seq_size, (offset - offs, sz + offs))
            offset += sz
        end
        shuffle!(seq_size)
        d = rand(UInt8(1):UInt8(127), offset) |> pointer |> unsafe_string
        for (off, sz) in seq_size
            push_substring!(buf, @view(d[off+1:off+sz]), off, off + sz == offset)
        end
        res = read!(buf.output)
        @test buf.output.bytes_written_count == offset
        @test res == d
    end
end