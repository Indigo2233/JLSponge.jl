try
    ts = time_ns()
    let
        test = ByteStreamTestHarness("construction", 15)
        execute(test, InputEnded(false))
        execute(test, BufferEmpty(true))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(0))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))
    end

    let
        test = ByteStreamTestHarness("construction-end", 15)
        execute(test, EndInput())
        execute(test, InputEnded(true))
        execute(test, BufferEmpty(true))
        execute(test, Eof(true))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(0))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))
    end
    tc = (Int(time_ns() - ts)) / 1e9
    @info "byte_stream_construction passed......... Time: $tc"
catch e
    println(stderr, e)
end