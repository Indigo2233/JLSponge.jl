try
    ts = time_ns()
    let
        test = ByteStreamTestHarness("write-end-pop", 15)

        execute(test, Write("cat"))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(12))
        execute(test, BufferSize(3))
        execute(test, Peek("cat"))

        execute(test, EndInput())

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(12))
        execute(test, BufferSize(3))
        execute(test, Peek("cat"))

        execute(test, Pop(3))

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(true))
        execute(test, Eof(true))
        execute(test, BytesRead(3))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))
    end
    let
        test = ByteStreamTestHarness("write-pop-end", 15)

        execute(test, Write("cat"))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(12))
        execute(test, BufferSize(3))
        execute(test, Peek("cat"))

        execute(test, Pop(3))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(true))
        execute(test, Eof(false))
        execute(test, BytesRead(3))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))

        execute(test, EndInput())

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(true))
        execute(test, Eof(true))
        execute(test, BytesRead(3))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))
    end
    let
        test = ByteStreamTestHarness("write-pop2-end", 15)

        execute(test, Write("cat"))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(12))
        execute(test, BufferSize(3))
        execute(test, Peek("cat"))

        execute(test, Pop(1))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(1))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(13))
        execute(test, BufferSize(2))
        execute(test, Peek("at"))

        execute(test, Pop(2))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(true))
        execute(test, Eof(false))
        execute(test, BytesRead(3))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))

        execute(test, EndInput())

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(true))
        execute(test, Eof(true))
        execute(test, BytesRead(3))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))
    end
    tc = (Int(time_ns() - ts)) / 1e9
    @info "byte_stream_one_write passed......... Time: $tc"

catch e
    println(stderr, e)
end