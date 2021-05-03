module JLSponge

using DataStructures
import Base: @kwdef

include("tcp_helpers/type_defs.jl")

include("type_defs.jl")
include("byte_stream.jl")
include("stream_reassembler.jl")
include("wrapping_integers.jl")
include("tcp_receiver.jl")

export ByteStream, error, end_input!, input_ended, buffer_empty, eof, peek_out,
       pop_output!, remain_cap, buffer_size

export StreamReassembler, push_substring!, stream_out, unassembled_bytes, isempty 

export WrappingInt32, TCPSegment, TCPHeader, wrap, unwrap

export TCPReceiver, ackno, window_size, unassembled_bytes, stream_out, segment_received!, assembled_bytes

end
