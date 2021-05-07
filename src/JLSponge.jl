module JLSponge

using DataStructures
import Base: @kwdef

include("tcp_helpers/type_defs.jl")
include("type_defs.jl")
include("tcp_helpers/tcp_state.jl")
include("byte_stream.jl")
include("stream_reassembler.jl")
include("wrapping_integers.jl")
include("tcp_receiver.jl")
include("tcp_sender.jl")
include("tcp_connection.jl")

export ByteStream, error, end_input!, input_ended, buffer_empty, eof, peek_out, pop_output!,
       remain_cap, buffer_size, write!

export StreamReassembler, push_substring!, stream_out, unassembled_bytes, isempty

export WrappingInt32, TCPSegment, TCPHeader, wrap, unwrap, state_summary

export TCPReceiver, ackno, window_size, unassembled_bytes, stream_out, segment_received!,
       assembled_bytes

export TCPSender, bytes_in_flight, next_seqno_absolute, next_seqno, segments_out, stream_in,
       fill_window!, send_seg!, ack_received!, tick!, consecutive_retransmissions,
       send_empty_segment!

end
