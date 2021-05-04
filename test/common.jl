using DataStructures
const SegmentArrives_Result_OK = true
const SegmentArrives_Result_NOT_SYN = false

@enum State begin
    LISTEN
    SYN_RCVD
    SYN_SENT
    SYN_ACKED
    FIN_RCVD
    FIN_SENT
    FIN_ACKED
    ESTABLISHED 
    CLOSE_WAIT   
    LAST_ACK    
    FIN_WAIT_1
    FIN_WAIT_2
    CLOSING    
    TIME_WAIT    
    CLOSED     
    RESET
    ERROR
end

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

function expect_seg(sender::TCPSender; 
    no_flag = nothing,
    ack=nothing, rst=nothing, syn=nothing, fin=nothing,
    payload_size=nothing, seqno=nothing, ackno=nothing,
    data=nothing, win = nothing)
    if no_flag !== nothing
        ack = isnothing(ack) ? false : ack
        rst = isnothing(rst) ? false : rst
        syn = isnothing(syn) ? false : syn
        fin = isnothing(fin) ? false : fin
    end

    segments = sender.segments_out
    isempty(segments) && error("No segs")
    seg = dequeue!(segments)
    hd = seg.header
    (!isnothing(ack) && hd.ack != ack) && error("ack error")
    (!isnothing(rst) && hd.rst != rst) && error("rst error")
    (!isnothing(syn) && hd.syn != syn) && error("syn error")
    (!isnothing(fin) && hd.fin != fin) && error("fin error")
    (!isnothing(seqno) && hd.seqno != seqno) && error("seqno error")
    (!isnothing(ackno) && hd.ackno != ackno) && error("ackno error")
    
    (!isnothing(win) && hd.win != win) && error("win error")
    (!isnothing(payload_size) && length(seg.payload) != payload_size) && error("payload_size error")
    (!isnothing(data) && seg.payload.storage[] != data) && error("data error")
    nothing
end

expect_no_seg(sender::TCPSender) = !isempty(sender.segments_out) && error("expect_no_seg")


function ack_received_test(sender::TCPSender, ackno, win_size::Integer=UInt16(137))
    ack_received!(sender, ackno, UInt16(win_size))
    fill_window!(sender)
end

function write_bytes(sender::TCPSender, bytes="", end_input=false)
    write!(stream_in(sender), bytes)
    end_input && end_input!(stream_in(sender))
    fill_window!(sender)
end

function expect_state(sender::TCPSender, state)
    state_summary(sender) != state && error("state error")
end