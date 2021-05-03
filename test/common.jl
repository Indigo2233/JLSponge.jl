const SegmentArrives_Result_OK = true
const SegmentArrives_Result_NOT_SYN = false

function build_seg(; data="", ack=false, rst=false, syn=false, fin=false,
                   seqno=WrappingInt32(0), ackno=WrappingInt32(0), win=UInt16(0))
    return seg = TCPSegment(TCPHeader(; ack, rst, syn, fin, seqno, ackno, win), data)
    return seg
end
function segment_arrives(receiver::TCPReceiver; data="", with_ack=nothing, with_syn=false,
                         with_fin=false, seqno=0, result=nothing)
    seg = build_seg(; data, syn=with_syn, fin=with_fin, seqno=WrappingInt32(seqno),
                    ack=with_ack !== nothing,
                    ackno=WrappingInt32(with_ack !== nothing ? with_ack : 0))
    segment_received!(receiver, seg)
    res = ackno(receiver) === nothing ? SegmentArrives_Result_NOT_SYN :
          SegmentArrives_Result_OK

    if result !== nothing && result != res
        error("TCPReceiver::segment_received!() reported `", result,
              "`, but it was expected to report `", res, "`")
    end
end