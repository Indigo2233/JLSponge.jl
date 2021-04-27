set_error(bs::ByteStream)::Nothing = (bs.error = true; nothing)

error(bs::ByteStream)::Bool = bs.error

end_input!(bs::ByteStream)::Nothing = (bs.has_eof = true; nothing)

input_ended(bs::ByteStream)::Bool = bs.has_eof

buffer_empty(bs::ByteStream)::Bool = isempty(bs.buf)

eof(bs::ByteStream)::Bool = bs.has_eof && isempty(bs.buf)

function peek_out(bs::ByteStream, len)
    @inbounds @simd for i in 1:len
        bs.str_arr[i] = bs.buf[i] 
    end
    return unsafe_string(pointer(bs.str_arr), len)
end

function pop_output!(bs::ByteStream, len) 
    bs.buf.first = mod1(bs.buf.first + len, bs.buf.capacity)
    bs.buf.length -= len
    bs.bytes_read_count += len
    nothing
end

remain_cap(bs::ByteStream)::Int = bs.buf.capacity - length(bs.buf)

buffer_size(bs::ByteStream)::Int = length(bs.buf)

function write!(bs::ByteStream, data::String)::Int
    isempty(data) && return 0
    bytes_to_write = min(length(data), remain_cap(bs))
    @inbounds append!(bs.buf, @view(codeunits(data)[1:bytes_to_write]))
    bs.bytes_written_count += bytes_to_write
    return bytes_to_write
end

function read!(bs::ByteStream, len)
    read_len = min(len, buffer_size(bs))
    s =  peek_out(bs, read_len)
    pop_output!(bs, read_len)
    return s
end