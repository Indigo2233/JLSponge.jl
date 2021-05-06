@testset "fsm_stream_reassembler_holes.jl" begin
    
    @testset begin 
        rs = StreamReassembler(65000) 
        push_substring!(rs, "b", 1)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        
        @test !eof(rs.output)
    end
    @testset begin 
        rs = StreamReassembler(65000) 
        push_substring!(rs, "b", 1)
        @test rs.cur_idx == 0 
        push_substring!(rs, "a", 0)
        @test rs.cur_idx == 2    
        @test read!(rs.output) == "ab"
        @test !eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(65000) 
        push_substring!(rs, "b", 1, true)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        push_substring!(rs, "a", 0)
        @test rs.cur_idx == 2    
        @test read!(rs.output) == "ab"
        @test eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(65000) 
        push_substring!(rs, "b", 1)
        push_substring!(rs, "ab", 0)

        @test rs.cur_idx == 2    
        @test read!(rs.output) == "ab"
        @test !eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(65000) 
        push_substring!(rs, "b", 1)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        push_substring!(rs, "d", 3)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        
        push_substring!(rs, "c", 2)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        
        push_substring!(rs, "ab", 0)

        @test rs.cur_idx == 4 
        @test read!(rs.output) == "abcd"
        @test !eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(65000) 
        push_substring!(rs, "b", 1)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        push_substring!(rs, "d", 3)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        push_substring!(rs, "abc", 0)

        @test rs.cur_idx == 4 
        @test read!(rs.output) == "abcd"
        @test !eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(65000) 
        push_substring!(rs, "b", 1)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        push_substring!(rs, "d", 3)
        @test rs.cur_idx == 0 
        @test read!(rs.output) == ""
        @test !eof(rs.output)

        push_substring!(rs, "a", 0)
        @test rs.cur_idx == 2
        @test read!(rs.output) == "ab"
        @test !eof(rs.output)

        push_substring!(rs, "c", 2)
        @test rs.cur_idx == 4
        @test read!(rs.output) == "cd"
        @test !eof(rs.output)

        push_substring!(rs, "", 4, true)

        @test rs.cur_idx == 4 
        @test read!(rs.output) == ""
        @test eof(rs.output)
    end

end