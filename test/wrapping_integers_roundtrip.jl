@testset "wrapping_integers_roundtrip.jl" begin
    check_roundtrip(isn::WrappingInt32, value::UInt, checkpoint::UInt) = @test unwrap(wrap(value, isn), isn, checkpoint) == value
    dist31minus1 = UInt32(0):(UInt(1) << 31)-1
    dist32 = UInt32(0):typemax(UInt32)
    dist63 = UInt(0):(UInt(1) << 63)
    big_offset = (UInt(1) << 31) - 1
    for i in 1:100_000
        isn = WrappingInt32(rand(dist32))
        val = rand(dist63)
        offset = rand(dist31minus1)
        check_roundtrip(isn, val, val)
        check_roundtrip(isn, val + 1, val)
        check_roundtrip(isn, val - 1, val)
        check_roundtrip(isn, val + offset, val)
        check_roundtrip(isn, val + big_offset, val)
        check_roundtrip(isn, val - big_offset, val) 
    end
end

"""
            check_roundtrip(isn, val, val);
            check_roundtrip(isn, val + 1, val);
            check_roundtrip(isn, val - 1, val);
            check_roundtrip(isn, val + offset, val);
            check_roundtrip(isn, val - offset, val);
            check_roundtrip(isn, val + big_offset, val);
            check_roundtrip(isn, val - big_offset, val);
        }
"""