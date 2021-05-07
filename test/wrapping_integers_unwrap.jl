@testset "wrapping_integers_unwrap.jl" begin
    @test unwrap(WrappingInt32(1), WrappingInt32(0), 0) == UInt(1)
    @test unwrap(WrappingInt32(1), WrappingInt32(0), typemax(UInt32)) == (UInt(1) << 32) + 1
    @test unwrap(WrappingInt32(typemax(UInt32) - 1), WrappingInt32(0),
                 3 * (UInt(1) << 32)) == 3 * (UInt(1) << 32) - 2
    @test unwrap(WrappingInt32(typemax(UInt32) - 10), WrappingInt32(0),
                 3 * (UInt(1) << 32)) == 3 * (UInt(1) << 32) - 11
    @test unwrap(WrappingInt32(typemax(UInt32)), WrappingInt32(10), 3 * (UInt(1) << 32)) ==
          3 * (UInt(1) << 32) - 11
    @test unwrap(WrappingInt32(typemax(UInt32)), WrappingInt32(0), 0) ==
          UInt(typemax(UInt32))
    @test unwrap(WrappingInt32(16), WrappingInt32(16), 0) == UInt(0)
    @test unwrap(WrappingInt32(15), WrappingInt32(16), 0) == UInt(typemax(UInt32))
    @test unwrap(WrappingInt32(0), WrappingInt32(typemax(Int32)), 0) ==
           UInt(typemax(Int32)) + 2
    @test unwrap(WrappingInt32(typemax(UInt32)), WrappingInt32(typemax(Int32)), 0) ==
           UInt(1) << 31
    @test unwrap(WrappingInt32(typemax(UInt32)), WrappingInt32(UInt(1) << 31), 0) ==
           UInt(typemax(UInt32)) >> 1
end