@testset "wrapping_integers_wrap.jl" begin
    @test wrap(3 * (UInt(1) << 32), WrappingInt32(0)) == WrappingInt32(0)
    @test wrap(3 * (UInt(1) << 32) + 17, WrappingInt32(15)) == WrappingInt32(32)
    @test wrap(7 * (UInt(1) << 32) - 2, WrappingInt32(15)) == WrappingInt32(13)    
end