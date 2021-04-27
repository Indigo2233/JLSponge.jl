try
    ts = time_ns()

    NREPS = 1000
    MIN_WRITE = 10
    MAX_WRITE = 200
    CAPACITY = MAX_WRITE * NREPS
    let
        test = ByteStreamTestHarness("many writes", CAPACITY)
        acc = 0

        for i in 1:NREPS
            rd = rand(UInt32)
            size = MIN_WRITE + (rd % (MAX_WRITE - MIN_WRITE))
            d = rand('a':'z', size) |> join

            execute(test, with_bytes_written!(Write(d), size))
            acc += size

            execute(test, InputEnded(false))
            execute(test, BufferEmpty(false))
            execute(test, Eof(false))
            execute(test, BytesRead(0))
            execute(test, BytesWritten(acc))
            execute(test, RemainingCapacity(CAPACITY - acc))
            execute(test, BufferSize(acc))
        end
    end
    tc = (Int(time_ns() - ts)) / 1e9
    @info "byte_stream_many_writes passed......... Time: $tc"

catch e
    println(stderr, e)
end