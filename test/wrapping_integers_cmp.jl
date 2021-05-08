@testset "wrapping_integers_cmp.jl" begin
    @testset begin
        @test WrappingInt32(3) != WrappingInt32(1)
        N_REPS = 4096
        for i in 1:N_REPS
            n = rand(typemin(UInt32):typemax(UInt32))
            diff = rand(UInt16(1):typemax(UInt16))
            m = n + diff
            @test WrappingInt32(m) != WrappingInt32(n)
        end
    end    
end

