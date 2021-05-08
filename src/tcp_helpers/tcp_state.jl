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

struct TCPState
    sender::State
    receiver::State
    active::Bool
    linger_after_streams_finish::Bool
    TCPState(sender, receiver, active, linger_after_streams_finish) = 
        new(sender, receiver, active, linger_after_streams_finish)
    TCPState(sender, receiver) = new(sender, receiver, true, true)
end

const TCP_STATE_DICT = Dict{State, TCPState}(
    LISTEN => TCPState(CLOSED, LISTEN),
    SYN_RCVD => TCPState(SYN_SENT, SYN_RCVD),
    SYN_SENT => TCPState(SYN_SENT, LISTEN),
    ESTABLISHED => TCPState(SYN_ACKED, SYN_RCVD),
    CLOSE_WAIT => TCPState(SYN_ACKED, FIN_RCVD, true, false),
    LAST_ACK => TCPState(FIN_SENT, FIN_RCVD, true, false),
    CLOSING => TCPState(FIN_SENT, FIN_RCVD),
    FIN_WAIT_1 => TCPState(FIN_SENT, SYN_RCVD),
    FIN_WAIT_2 => TCPState(FIN_ACKED, SYN_RCVD),
    TIME_WAIT => TCPState(FIN_ACKED, FIN_RCVD),
    RESET => TCPState(ERROR, ERROR, false, false),
    CLOSED => TCPState(FIN_ACKED, FIN_RCVD, false, false)
)

TCPState(state::State) = TCP_STATE_DICT[state]

TCPState(sender::TCPSender, receiver::TCPReceiver, active::Bool, linger::Bool) = 
    TCPState(state_summary(sender), state_summary(receiver), active, active ? linger : false)

TCPState(conn::TCPConnection) = 
    TCPState(conn.sender, conn.receiver, conn.active, conn.linger_after_streams_finish)

function state_summary(receiver::TCPReceiver)
    error(stream_out(receiver)) && return ERROR 
    isnothing(ackno(receiver)) && return LISTEN
    input_ended(stream_out(receiver)) && return FIN_RCVD
    return SYN_RCVD
end

function state_summary(sender::TCPSender)
    error(stream_in(sender)) && return ERROR 
    next_seqno_absolute(sender) == 0 && return CLOSED
    next_seqno_absolute(sender) == bytes_in_flight(sender) && return SYN_SENT
    !eof(stream_in(sender)) && return SYN_ACKED
    next_seqno_absolute(sender) < stream_in(sender).bytes_written_count + 2 && return SYN_ACKED
    bytes_in_flight(sender) != 0 && return FIN_SENT
    return FIN_ACKED
end

