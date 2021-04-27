try
    ts = time_ns()
    let
        test = ByteStreamTestHarness("write-write-end-pop-pop", 15)

        execute(test, Write("cat"))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(12))
        execute(test, BufferSize(3))
        execute(test, Peek("cat"))

        execute(test, Write("tac"))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(6))
        execute(test, RemainingCapacity(9))
        execute(test, BufferSize(6))
        execute(test, Peek("cattac"))

        execute(test, EndInput())

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(6))
        execute(test, RemainingCapacity(9))
        execute(test, BufferSize(6))
        execute(test, Peek("cattac"))

        execute(test, Pop(2))

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(2))
        execute(test, BytesWritten(6))
        execute(test, RemainingCapacity(11))
        execute(test, BufferSize(4))
        execute(test, Peek("ttac"))

        execute(test, Pop(4))

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(true))
        execute(test, Eof(true))
        execute(test, BytesRead(6))
        execute(test, BytesWritten(6))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))
    end

    let
        test = ByteStreamTestHarness("write-pop-write-end-pop", 15)

        execute(test, Write("cat"))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(12))
        execute(test, BufferSize(3))
        execute(test, Peek("cat"))

        execute(test, Pop(2))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(2))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(14))
        execute(test, BufferSize(1))
        execute(test, Peek("t"))

        execute(test, Write("tac"))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(2))
        execute(test, BytesWritten(6))
        execute(test, RemainingCapacity(11))
        execute(test, BufferSize(4))
        execute(test, Peek("ttac"))

        execute(test, EndInput())

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(2))
        execute(test, BytesWritten(6))
        execute(test, RemainingCapacity(11))
        execute(test, BufferSize(4))
        execute(test, Peek("ttac"))

        execute(test, Pop(4))

        execute(test, InputEnded(true))
        execute(test, BufferEmpty(true))
        execute(test, Eof(true))
        execute(test, BytesRead(6))
        execute(test, BytesWritten(6))
        execute(test, RemainingCapacity(15))
        execute(test, BufferSize(0))
    end
    tc = (Int(time_ns() - ts)) / 1e9
    @info "byte_stream_two_writes passed......... Time: $tc"
catch e
    println(stderr, e)
end