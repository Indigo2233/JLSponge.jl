using DataStructures
using JLSponge
using Test
const SegmentArrives_Result_OK = true
const SegmentArrives_Result_NOT_SYN = false
const DEFAULT_TEST_WINDOW = UInt(137)

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


function expect_seg(segments::Queue{TCPSegment}; 
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
    seg
end

function expect_seg(sender::TCPSender; 
    no_flag = nothing,
    ack=nothing, rst=nothing, syn=nothing, fin=nothing,
    payload_size=nothing, seqno=nothing, ackno=nothing,
    data=nothing, win = nothing)

    expect_seg(sender.segments_out; no_flag, ack, rst, syn, fin, payload_size, seqno, ackno, data, win)
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

fsm_in_listen(;cap::Int=64000, retx_timeout::UInt16=UInt16(1000), fixed_isn=nothing) = 
    TCPConnection(;cap, retx_timeout, fixed_isn)
    
function fsm_in_syn_sent(fixed_isn; cap::Int=64000, retx_timeout::UInt16=UInt16(1000))
   conn = TCPConnection(;cap, retx_timeout, fixed_isn)
   connect!(conn)
   expect_one_seg(conn; no_flag=true, syn=true, seqno=fixed_isn, payload_size=0)
   conn
end

function fsm_in_established(tx_isn::WrappingInt32=WrappingInt32(0), 
    rx_isn::WrappingInt32=WrappingInt32(0))

    conn = fsm_in_syn_sent(tx_isn)
    send_syn!(conn, rx_isn, tx_isn + 1)
    expect_one_seg(conn; no_flag=true, ack=true, ackno=rx_isn + 1, payload_size=0)
    conn
end

function fsm_in_close_wait(tx_isn::WrappingInt32=WrappingInt32(0), 
    rx_isn::WrappingInt32=WrappingInt32(0))

    conn = fsm_in_established()
    send_fin!(conn, rx_isn + 1, tx_isn + 1)
    expect_one_seg(conn, no_flag=true, ack=true, ackno=rx_isn+2)
    conn
end

function fsm_in_last_ack(tx_isn::WrappingInt32=WrappingInt32(0), 
    rx_isn::WrappingInt32=WrappingInt32(0))

    conn = fsm_in_close_wait(rx_isn, rx_isn) 
    conn |> end_input_stream!
    expect_one_seg(conn, no_flag=true, fin=true, ack=true, ackno=rx_isn+1, seqno=tx_isn+2)
    conn
end

function fsm_in_fin_wait_1(tx_isn::WrappingInt32=WrappingInt32(0), 
    rx_isn::WrappingInt32=WrappingInt32(0))

    conn = fsm_in_established(tx_isn, rx_isn)
    conn |> end_input_stream!
    expect_one_seg(conn, no_flag=true, fin=true, ack=true, ackno=rx_isn+1, seqno=tx_isn+1)
    conn
end

function fsm_in_fin_wait_2(tx_isn::WrappingInt32=WrappingInt32(0), 
    rx_isn::WrappingInt32=WrappingInt32(0))

    conn = fsm_in_fin_wait_1(tx_isn, rx_isn)
    send_ack!(conn, rx_isn + 1, tx_isn + 2)
    conn   
end

function fsm_in_closing(tx_isn::WrappingInt32=WrappingInt32(0), 
    rx_isn::WrappingInt32=WrappingInt32(0))

    conn = fsm_in_fin_wait_1(tx_isn, rx_isn)
    send_fin!(conn, rx_isn + 1, tx_isn + 1)
    expect_one_seg(conn, no_flag=true, ack=true, ackno=rx_isn+2)
    conn
end

function fsm_in_time_wait(tx_isn::WrappingInt32=WrappingInt32(0), 
    rx_isn::WrappingInt32=WrappingInt32(0))

    conn = fsm_in_fin_wait_1(tx_isn, rx_isn)
    send_fin!(conn, rx_isn + 1, tx_isn + 2)
    expect_one_seg(conn, no_flag=true, ack=true, ackno=rx_isn+2)
    conn
end

function expect_one_seg(conn::TCPConnection; 
    no_flag=nothing,
    ack=nothing, rst=nothing, syn=nothing, fin=nothing,
    payload_size=nothing, seqno=nothing, ackno=nothing,
    data=nothing, win = nothing)

    seg = expect_seg(conn.segments_out; no_flag, ack, rst, syn, fin, payload_size, seqno, ackno, data, win)
    @test conn.segments_out |> isempty
    seg
end

function send_syn!(conn::TCPConnection, seqno::WrappingInt32, ackno=nothing)
    ackno === nothing ?
    send_seg!(conn; syn=true, seqno) :
    send_seg!(conn; syn=true, seqno, ack=true, ackno)
end

function send_seg!(conn::TCPConnection; 
    ack=false, rst=false, syn=false, fin=false,
    seqno=WrappingInt32(0), ackno=WrappingInt32(0),
    data="", win = UInt16(0))

    seg = build_seg(;data, ack, rst, syn, fin, seqno, ackno, win)
    segment_received!(conn, seg)
    nothing
end

function send_ack!(conn::TCPConnection, seqno::WrappingInt32, ackno::WrappingInt32, swin=DEFAULT_TEST_WINDOW)
    win = swin
    send_seg!(conn; ack=true, win, seqno, ackno) 
end

function send_rst!(conn::TCPConnection, seqno::WrappingInt32, ackno=nothing)
    ackno === nothing ?
    send_seg!(conn; seqno, rst=true) :
    send_seg!(conn; seqno, rst=true, ackno=ackno, ack=true)
end

function send_fin!(conn::TCPConnection, seqno::WrappingInt32, ackno=nothing)
    ackno === nothing ?
    send_seg!(conn; seqno, fin=true) :
    send_seg!(conn; seqno, fin=true, ack=true, ackno=ackno)    
end

function send_byte!(conn::TCPConnection, 
    seqno::WrappingInt32, 
    ackno::Union{WrappingInt32, Nothing}, val::Char)

    ackno === nothing ?
    send_seg!(conn; seqno, data=string(val)) :
    send_seg!(conn; seqno, data=string(val), ackno=ackno, ack=true)
end

expect_state(conn::TCPConnection, state::JLSponge.State) = @test TCPState(conn) == TCPState(state)

expect_notin_state(conn::TCPConnection, state::JLSponge.State) = @test TCPState(conn) != TCPState(state)

expect_no_seg(conn::TCPConnection) = @test isempty(conn.segments_out)

function expect_data!(conn::TCPConnection, data::Nothing=nothing)
    bytes_avail = inbound_stream(conn) |> buffer_size
    actual_data = read!(inbound_stream(conn), bytes_avail)
end

function expect_data!(conn::TCPConnection, data::String)
    actual_data = expect_data!(conn)
    @test data == actual_data
end

function expect_no_data(conn::TCPConnection)
    @test inbound_stream(conn) |> buffer_size == 0
end
