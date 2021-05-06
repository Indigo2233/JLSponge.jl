@testset "fsm_stream_reassembler_cap.jl" begin
    @testset begin
        rs = StreamReassembler(2)
        push_substring!(rs, "ab", 0)
        @test rs.cur_idx == 2
        @test read!(rs.output) == "ab"

        push_substring!(rs, "cd", 2)
        @test rs.cur_idx == 4
        @test read!(rs.output) == "cd"
        
        push_substring!(rs, "ef", 4)
        @test rs.cur_idx == 6
        @test read!(rs.output) == "ef"
    end

    @testset begin
        rs = StreamReassembler(2)
        push_substring!(rs, "ab", 0)
        @test rs.cur_idx == 2
        push_substring!(rs, "cd", 2)
        
        @test rs.cur_idx == 2
        @test read!(rs.output) == "ab"

        push_substring!(rs, "cd", 2)
        @test rs.cur_idx == 4
        @test read!(rs.output) == "cd"
    end
    @testset begin
        rs = StreamReassembler(1)
        push_substring!(rs, "ab", 0)
        @test rs.cur_idx == 1 
        
        push_substring!(rs, "ab", 0)
        @test rs.cur_idx == 1 
        
        @test read!(rs.output) == "a"

        push_substring!(rs, "abc", 0)
        @test rs.cur_idx == 2 
        @test read!(rs.output) == "b"
        @test rs.cur_idx == 2 
    end

    @testset begin
        rs = StreamReassembler(3)
        for i in 0:3:99997
            seg = Char.(rand(1:125, 6)) |> string
            push_substring!(rs, seg, i)
            @test rs.cur_idx == i + 3
            @test read!(rs.output) == SubString(seg, 1:3)
        end
    end
end