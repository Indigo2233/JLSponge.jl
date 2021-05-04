function main()
    let 
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1))
        write_bytes(sender, "a")
        expect_seg(sender, no_flag=true, data="a")
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_no_seg(sender)
    end

    let 
        isn = rand(UInt32(0):typemax(UInt32))
        sender = TCPSender(fixed_isn=WrappingInt32(isn))
        fill_window!(sender)
        expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1))
        write_bytes(sender, "a")
        expect_seg(sender, no_flag=true, data="a")
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 2))
    
        write_bytes(sender, "b")
        expect_seg(sender, no_flag=true, data="b")
        expect_no_seg(sender)
        ack_received_test(sender, WrappingInt32(isn + 1))
        expect_no_seg(sender)
    end

    
end
main()
let 
    isn = rand(UInt32(0):typemax(UInt32))
    sender = TCPSender(fixed_isn=WrappingInt32(isn))
    fill_window!(sender)
    expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
    expect_no_seg(sender)
    ack_received_test(sender, WrappingInt32(isn + 1))
    write_bytes(sender, "a")
    expect_seg(sender, no_flag=true, data="a")
    expect_no_seg(sender)
    ack_received_test(sender, WrappingInt32(isn + 2))

    write_bytes(sender, "b")
    expect_seg(sender, no_flag=true, data="b")
    expect_no_seg(sender)
    ack_received_test(sender, WrappingInt32(isn + 1))
    expect_no_seg(sender)
end


let 
    isn = rand(UInt32(0):typemax(UInt32))
    sender = TCPSender(fixed_isn=WrappingInt32(isn))
    fill_window!(sender)
    expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
    expect_state(sender, SYN_SENT)
    ack_received_test(sender, WrappingInt32(isn + 2), 1000)
    expect_state(sender, SYN_SENT)
end

let 
    isn = rand(UInt32(0):typemax(UInt32))
    sender = TCPSender(fixed_isn=WrappingInt32(isn))
    fill_window!(sender)
    expect_seg(sender, no_flag=true, syn=true, payload_size=0, seqno=WrappingInt32(isn))
    expect_state(sender, SYN_SENT)
    ack_received_test(sender, WrappingInt32(isn + 2), 1000)
    expect_state(sender, SYN_SENT)
end