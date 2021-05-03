import Base.-, Base.+
@inline -(a::WrappingInt32, b::WrappingInt32) = a.val - b.val
@inline +(a::WrappingInt32, b::UInt32) = WrappingInt32(a.val + b)
@inline -(a::WrappingInt32, b::UInt32) = a + -b

function wrap(n::UInt, isn::WrappingInt32)
    tmp = UInt32((n << 32 >> 32))
    return isn + tmp
end

function unwrap(n::WrappingInt32, isn::WrappingInt32, checkpoint::Integer)
    ckpt = UInt(checkpoint)
    absolute_seqno_64 = UInt((n.val - isn.val))
    (ckpt <= absolute_seqno_64) && return absolute_seqno_64
    size_period = 0x100000000
    quotient = (ckpt - absolute_seqno_64) >> 32
    remainder = (ckpt - absolute_seqno_64) << 32 >> 32
    return absolute_seqno_64 + ((quotient + (remainder >= size_period ÷ 2)) << UInt32(32))
end
