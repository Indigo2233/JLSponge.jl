struct WrappingInt32
    val::UInt32
end

@kwdef mutable struct TCPHeader
    sport::UInt16 = 0
    dport::UInt16 = 0
    seqno::WrappingInt32 = WrappingInt32(0)
    ackno::WrappingInt32 = WrappingInt32(0)
    doff::UInt8 = 5
    urg::Bool = false
    ack::Bool = false
    psh::Bool = false
    rst::Bool = false
    syn::Bool = false
    fin::Bool = false
    win::UInt16 = 0
    cksum::UInt16 = 0
    uptr::UInt16 = 0
end

struct Buffer
    storage::Union{Base.RefValue{String}, Base.RefValue{SubString{String}}}
end

struct TCPSegment
    header::TCPHeader
    payload::Buffer
    TCPSegment(data::String) = new(TCPHeader(), Buffer(Ref(data)))
    TCPSegment(header::TCPHeader, data) = new(header, Buffer(Ref(data)))
end

@inline Base.length(bf::Buffer) = length(bf.storage[])
@inline length_in_sequence_space(seg::TCPSegment) = length(seg.payload.storage[]) + seg.header.syn + seg.header.fin