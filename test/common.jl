using DataStructures
using JLSponge
using Test
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

    result !== nothing && @test result == res    
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

    segments = segments_out(sender)
    isempty(segments) && error("No segs")
    seg = dequeue!(segments)
    hd = seg.header
    !isnothing(ack) && @test hd.ack == ack
    !isnothing(rst) && @test hd.rst == rst
    !isnothing(syn) && @test hd.syn == syn
    !isnothing(fin) && @test hd.fin == fin
    !isnothing(seqno) && @test hd.seqno == seqno
    !isnothing(ackno) && @test hd.ackno == ackno
    
    !isnothing(win) && @test hd.win == win
    !isnothing(payload_size) && @test length(seg.payload) == payload_size
    !isnothing(data) && @test seg.payload.storage[] == data
    nothing
end

expect_no_seg(sender::TCPSender) = @test isempty(sender.segments_out) 

function ack_received_test(sender::TCPSender, ackno, win_size::Integer=UInt16(137))
    ack_received!(sender, ackno, UInt16(win_size))
    fill_window!(sender)
end

function write_bytes!(sender::TCPSender, bytes="", end_input=false)
    write!(stream_in(sender), bytes)
    end_input && end_input!(stream_in(sender))
    fill_window!(sender)
end

function expect_state(sender::TCPSender, state)
    @test state_summary(sender) == state
end

sender_close(sender::TCPSender) = write_bytes!(sender, "", true)
