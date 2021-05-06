@testset "fsm_stream_reassembler_dup.jl" begin
        
    @testset begin
        rs = StreamReassembler(65000)
        push_substring!(rs, "abcd", 0)
        @test rs.cur_idx == 4
        @test read!(rs.output) == "abcd"
        @test !eof(rs.output)

        push_substring!(rs, "abcd", 0)
        @test rs.cur_idx == 4
        @test read!(rs.output) == ""
        @test !eof(rs.output)
    end 
    @testset begin
        rs = StreamReassembler(65000)
        push_substring!(rs, "abcd", 0)
        @test rs.cur_idx == 4
        @test read!(rs.output) == "abcd"
        @test !eof(rs.output)

        push_substring!(rs, "abcd", 4)
        @test rs.cur_idx == 8
        @test read!(rs.output) == "abcd"
        @test !eof(rs.output)

        push_substring!(rs, "abcd", 0)
        @test rs.cur_idx == 8
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        push_substring!(rs, "abcd", 4)
        @test rs.cur_idx == 8
        @test read!(rs.output) == ""
        @test !eof(rs.output)    
    end 

    @testset begin
        rs = StreamReassembler(65000)
        push_substring!(rs, "abcdefgh", 0)
        @test rs.cur_idx == 8
        @test read!(rs.output) == "abcdefgh"
        @test !eof(rs.output)
        data = "abcdefgh"
        for _ in 1:1000
            st = rand(0:8)
            ed = rand(st:8)
            push_substring!(rs, @view(data[st+1:ed]), st)
            @test rs.cur_idx == 8
            @test read!(rs.output) == ""
            @test !eof(rs.output)
        end
    end 

    @testset begin
        rs = StreamReassembler(65000)
        push_substring!(rs, "abcd", 0)
        @test rs.cur_idx == 4
        @test read!(rs.output) == "abcd"
        @test !eof(rs.output)

        push_substring!(rs, "abcdef", 0)
        @test rs.cur_idx == 6
        @test read!(rs.output) == "ef"
        @test !eof(rs.output)
    end 

end