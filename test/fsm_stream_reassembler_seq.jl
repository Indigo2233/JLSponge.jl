@testset "fsm_stream_reassembler_seq.jl" begin
    @testset begin 
        rs = StreamReassembler(65000)
        push_substring!(rs, "abcd", 0)
        @test rs.cur_idx == 4
        read!(rs.output) == "abcd"
        @test !eof(rs.output)

        push_substring!(rs, "efgh", 4)
        @test rs.cur_idx == 8
        read!(rs.output) == "efgh"
        @test !eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(65000)
        push_substring!(rs, "abcd", 0)
        @test rs.cur_idx == 4
        @test !eof(rs.output)

        push_substring!(rs, "efgh", 4)
        @test rs.cur_idx == 8
        read!(rs.output) == "abcdefgh"
        @test !eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(65000)
        ss = IOBuffer()
        for i in 0:99
            @test rs.cur_idx == 4i
            push_substring!(rs, "abcd", 4i)
            @test !eof(rs.output)
            write(ss, "abcd")
        end
        @test read!(rs.output) == take!(ss) |> String
        @test !eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(65000)
        
        for i in 0:99
            @test rs.cur_idx == 4i
            push_substring!(rs, "abcd", 4i)
            @test !eof(rs.output)
            @test read!(rs.output) == "abcd"
        end
        @test !eof(rs.output)
    end
end