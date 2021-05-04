import Base.==, Base.!=
@kwdef mutable struct TCPState
    sender::String = ""
    receiver::String = ""
    active::Bool = true
    linger_after_streams_finish::Bool = true
end 

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

function state_summary(receiver::TCPReceiver)
    error(stream_out(receiver)) && return ERROR 
    !isnothing(ackno(receiver)) && return LISTEN
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

