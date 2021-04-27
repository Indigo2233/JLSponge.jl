
abstract type ByteStreamTestStep end

abstract type ByteStreamExpectation <: ByteStreamTestStep end

abstract type ByteStreamAction <: ByteStreamTestStep end

struct ByteStreamExpectationViolation <: Exception 
    msg::String
end

function property(::Type{ByteStreamExpectationViolation}, property_name, expected, actual)
    "The ByteStream should have had " * property_name * " equal to " *
    string(expected) * " but instead it was " * string(actual)
end

struct EndInput <: ByteStreamAction end

description(ei::EndInput) = "end input"

execute(::EndInput, bs::ByteStream)::Nothing = JLSponge.end_input!(bs) 


mutable struct Write <: ByteStreamAction
    data::String
    bytes_written::Union{UInt, Nothing}
    Write(data::String) = new(data, nothing)
end

with_bytes_written!(wt::Write, bytes_written) = (wt.bytes_written = bytes_written; wt)

description(wt::Write) = "write \"" + wt.data + "\" to the stream"


function execute(wt::Write, bs::ByteStream)::Nothing
    bytes_written = JLSponge.write!(bs, wt.data)
    if (wt.bytes_written !== nothing && bytes_written != wt.bytes_written) 
        throw(property(ByteStreamExpectationViolation, "bytes_written", wt.bytes_written, bytes_written))
    end
    nothing
end


struct Pop <: ByteStreamAction
    len::UInt
end

description(pop::Pop)::String = "pop " * string(pop.len)

execute(pop::Pop, bs::ByteStream)::Nothing = JLSponge.pop_output!(bs, pop.len)


struct InputEnded <: ByteStreamExpectation
    input_ended::Bool
end

description(inp_ed::InputEnded) = "input_ended: " + string(inp_ed.input_ended)

function execute(inp_ed::InputEnded, bs::ByteStream)::Nothing
    input_ended = JLSponge.input_ended(bs)
    (input_ended == inp_ed.input_ended) ||
        throw(property(ByteStreamExpectationViolation, "input_ended", inp_ed.input_ended, input_ended))
    nothing
end

struct BufferEmpty <: ByteStreamExpectation
    buffer_empty::Bool
end

description(bfe::BufferEmpty) = "buffer_empty: " * string(bfe.buffer_empty);

function execute(bfe::BufferEmpty, bs::ByteStream)::Nothing
    buffer_empty = JLSponge.buffer_empty(bs)
    (bfe.buffer_empty == buffer_empty) ||
        throw(property(ByteStreamExpectationViolation, "buffer_empty", bfe.buffer_empty, buffer_empty))
    nothing
end

struct Eof <: ByteStreamExpectation
    eof::Bool
end

description(e::Eof) = "eof: " * string(e.eof)

function execute(e::Eof, bs::ByteStream)::Nothing
    e1 = JLSponge.eof(bs)
    (e.eof == e1) ||
        throw(property(ByteStreamExpectationViolation, "eof", e.eof, e1))
    nothing
end


struct BufferSize <: ByteStreamExpectation
    buffer_size::UInt
end

description(bfsize::BufferSize) = "buffer_size: " * string(bfsize.buffer_size)

function execute(bfsize::BufferSize, bs::ByteStream)::Nothing
    buffer_size = JLSponge.buffer_size(bs)
    (bfsize.buffer_size == buffer_size) ||
        throw(property(ByteStreamExpectationViolation, "buffer_size", bfsize.buffer_size, buffer_size))
    nothing
end



struct RemainingCapacity <: ByteStreamExpectation
    remaining_capacity::UInt
end

description(rcap::RemainingCapacity) = "remaining_capacity: " * string(rcap.remaining_capacity)

function execute(rcap::RemainingCapacity, bs::ByteStream)::Nothing
    remaining_capacity = JLSponge.remain_cap(bs)
    (rcap.remaining_capacity == remaining_capacity) ||
        throw(property(ByteStreamExpectationViolation, "remaining_capacity", rcap.remaining_capacity, remaining_capacity))
    nothing
end


struct BytesWritten <: ByteStreamExpectation
    bytes_written::UInt
end

description(bwrt::BytesWritten) = "bytes_written: " * string(bwrt.bytes_written)

function execute(bwrt::BytesWritten, bs::ByteStream)::Nothing
    bytes_written = bs.bytes_written_count
    (bwrt.bytes_written == bytes_written) ||
        throw(property(ByteStreamExpectationViolation, "bytes_written", bwrt.bytes_written, bytes_written))
    nothing
end


struct BytesRead <: ByteStreamExpectation
    bytes_read::UInt
end

description(brd::BytesRead) = "bytes_read: " * string(brd.bytes_read)

function execute(brd::BytesRead, bs::ByteStream)::Nothing
    bytes_read = bs.bytes_read_count
    (brd.bytes_read == bytes_read) ||
        throw(property(ByteStreamExpectationViolation, "bytes_read", brd.bytes_read, bytes_read))
    nothing
end


struct Peek <: ByteStreamExpectation
    output::String
end

description(pk::Peek) = "\"" * pk.output * "\" at the front of the stream";

function execute(pk::Peek, bs::ByteStream)::Nothing
    output = JLSponge.peek_out(bs, pk.output |> length)
    (pk.output == output) ||
        throw(ByteStreamExpectationViolation("Expected \"" * pk.output * "\" at the front of the stream, but found \"" * output * "\""))
    nothing
end

struct ByteStreamTestHarness
    test_name::String
    byte_stream::ByteStream
    steps_executed::Vector{String}
    ByteStreamTestHarness(test_name, capacity) = 
        new(test_name, ByteStream(capacity), ["Initialized with (capacity=$capacity)"])
end

function execute(bstest::ByteStreamTestHarness, step::ByteStreamTestStep)
    try
        execute(step, bstest.byte_stream)
        push!(bstest.steps_executed, step |> string)
    catch e
        print(stderr, "Test Failure on expectation:\n\t $(string(step))")
        if isa(e, ByteStreamExpectationViolation)
            print(stderr, "\n\nFailure message:\n\t$(e.msg)")
            new_exception = "The test \"" * bstest.test_name * "\" failed"
        else
            print(stderr, "\n\nException:\n\t$(e)")
            new_exception = "The test \"" * bstest.test_name * "\" caused your implementation to throw an exception!"
        end
        print(stderr, "\n\nList of steps that executed successfully:")
        for s in bstest.steps_executed 
            print(stderr, "\n\t", s)
        end
        print(stderr, "\n\n")
        flush(stderr)
        throw(ByteStreamExpectationViolation(new_exception))
    end
end

