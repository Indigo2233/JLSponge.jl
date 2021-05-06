@testset "fsm_stream_reassembler_many.jl" begin
    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "a", 0)
        push_substring!(rs, "ab", 0)

        @test rs.cur_idx == 2
        @test read!(rs.output) == "ab"
        @test !eof(rs.output)
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "a", 0)
        @test read!(rs.output) == "a"

        push_substring!(rs, "ab", 0)

        @test rs.cur_idx == 2
        @test read!(rs.output) == "b"
    end
    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        @test read!(rs.output) == ""

        push_substring!(rs, "ab", 0)

        @test rs.cur_idx == 2
        @test read!(rs.output) == "ab"

        @test rs.unassembled_bytes == 0
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        @test read!(rs.output) == ""

        push_substring!(rs, "bc", 1)
        @test read!(rs.output) == ""

        @test rs.cur_idx == 0
        @test rs.unassembled_bytes == 2
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "c", 2)
        @test read!(rs.output) == ""

        push_substring!(rs, "bcd", 1)
        @test read!(rs.output) == ""

        @test rs.cur_idx == 0
        @test rs.unassembled_bytes == 3
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        push_substring!(rs, "d", 3)
        @test read!(rs.output) == ""
        
        push_substring!(rs, "bcde", 1)
        @test read!(rs.output) == ""

        @test rs.cur_idx == 0
        @test rs.unassembled_bytes == 4
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "c", 2)
        push_substring!(rs, "bcd", 1)
        @test read!(rs.output) == ""
        @test rs.cur_idx == 0
        @test rs.unassembled_bytes == 3
        
        push_substring!(rs, "a", 0)
        @test read!(rs.output) == "abcd"

        @test rs.cur_idx == 4
        @test rs.unassembled_bytes == 0
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "bcd", 1)
        push_substring!(rs, "c", 2)
        @test read!(rs.output) == ""
        @test rs.cur_idx == 0
        @test rs.unassembled_bytes == 3
        
        push_substring!(rs, "a", 0)
        @test read!(rs.output) == "abcd"

        @test rs.cur_idx == 4
        @test rs.unassembled_bytes == 0
    end

end