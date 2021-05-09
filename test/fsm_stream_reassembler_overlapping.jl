@testset "fsm_stream_reassembler_overlapping.jl" begin
    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "a", 0)
        push_substring!(rs, "ab", 0)
        
        @test rs.cur_idx == 2
        read!(rs.output) == "ab"
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "a", 0)
        read!(rs.output) == "a"

        push_substring!(rs, "ab", 0)
        
        @test rs.cur_idx == 2
        read!(rs.output) == "a"

    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        read!(rs.output) == ""

        push_substring!(rs, "ab", 0)
    
        read!(rs.output) == "ab"
        @test rs.unassembled_bytes == 0
        @test rs.cur_idx == 2
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        read!(rs.output) == ""

        push_substring!(rs, "bc", 1)
    
        read!(rs.output) == ""
        @test rs.unassembled_bytes == 2
        @test rs.cur_idx == 0
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "c", 2)
        read!(rs.output) == ""

        push_substring!(rs, "bcd", 1)
    
        read!(rs.output) == ""
        @test rs.unassembled_bytes == 3
        @test rs.cur_idx == 0
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        push_substring!(rs, "d", 3)
        read!(rs.output) == ""

        push_substring!(rs, "bcde", 1)
    
        read!(rs.output) == ""
        @test rs.unassembled_bytes == 4
        @test rs.cur_idx == 0
    end

    @testset begin 
        rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        push_substring!(rs, "bcd", 1)
        read!(rs.output) == ""
        @test rs.unassembled_bytes == 3
        @test rs.cur_idx == 0

        push_substring!(rs, "a", 0)
    
        read!(rs.output) == "abcd"
        @test rs.unassembled_bytes == 0
        @test rs.cur_idx == 4
    end

    @testset begin 
        rs = StreamReassembler(1000)

        push_substring!(rs, "bcd", 1)
        push_substring!(rs, "c", 2)

        read!(rs.output) == ""
        @test rs.unassembled_bytes == 3
        @test rs.cur_idx == 0

        push_substring!(rs, "a", 0)
    
        read!(rs.output) == "abcd"
        @test rs.unassembled_bytes == 0
        @test rs.cur_idx == 4
    end
end