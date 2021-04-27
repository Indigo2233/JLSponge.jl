# @testset "byte_stream_capacity.jl" begin
try
    ts = time_ns()
    let
        test = ByteStreamTestHarness("overwrite", 2)
        execute(test, with_bytes_written!(Write("cat"), 2))
        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(2))
        execute(test, RemainingCapacity(0))
        execute(test, BufferSize(2))
        execute(test, Peek("ca"))

        execute(test, with_bytes_written!(Write("t"), 0))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(0))
        execute(test, BytesWritten(2))
        execute(test, RemainingCapacity(0))
        execute(test, BufferSize(2))
        execute(test, Peek("ca"))
    end

    let
        test = ByteStreamTestHarness("overwrite-clear-overwrite", 2)

        execute(test, with_bytes_written!(Write("cat"), 2))
        execute(test, Pop(2))
        execute(test, with_bytes_written!(Write("tac"), 2))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(2))
        execute(test, BytesWritten(4))
        execute(test, RemainingCapacity(0))
        execute(test, BufferSize(2))
        execute(test, Peek("ta"))
    end
    let
        test = ByteStreamTestHarness("overwrite-pop-overwrite", 2)

        execute(test, with_bytes_written!(Write("cat"), 2))
        execute(test, Pop(1))
        execute(test, with_bytes_written!(Write("tac"), 1))

        execute(test, InputEnded(false))
        execute(test, BufferEmpty(false))
        execute(test, Eof(false))
        execute(test, BytesRead(1))
        execute(test, BytesWritten(3))
        execute(test, RemainingCapacity(0))
        execute(test, BufferSize(2))
        execute(test, Peek("at"))
    end
    

    let
        test = ByteStreamTestHarness("long-stream", 3)

        execute(test, with_bytes_written!(Write("abcdef"), 3))
        execute(test, Peek("abc"))
        execute(test, Pop(1))

        for _ in 0:99997
            execute(test, RemainingCapacity(1))
            execute(test, BufferSize(2))
            execute(test, with_bytes_written!(Write("abc"), 1))
            execute(test, RemainingCapacity(0))
            execute(test, Peek("bca"))
            execute(test, Pop(1))

            execute(test, RemainingCapacity(1))
            execute(test, BufferSize(2))
            execute(test, with_bytes_written!(Write("bca"), 1))
            execute(test, RemainingCapacity(0))
            execute(test, Peek("cab"))
            execute(test, Pop(1))

            execute(test, RemainingCapacity(1))
            execute(test, BufferSize(2))
            execute(test, with_bytes_written!(Write("cab"), 1))
            execute(test, RemainingCapacity(0))
            execute(test, Peek("abc"))
            execute(test, Pop(1))
        end

        execute(test, EndInput())
        execute(test, Peek("bc"))
        execute(test, Pop(2))
        execute(test, Eof(true))
    end
    tc = (time_ns() - ts |> Int) / 1e9
    @info "byte_stream_capacity passed........... Time: $tc"
catch e
    println(stderr, e)
end
