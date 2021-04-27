module JLSponge

using DataStructures

include("type_defs.jl")

include("byte_stream.jl")

include("stream_reassembler.jl")

export ByteStream, StreamReassembler

end
