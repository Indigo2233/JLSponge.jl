@testset "fsm_stream_reassembler_single.jl" begin
    @testset begin
        sr = StreamReassembler(65000)
        @test sr.cur_idx == 0
        @test read!(sr.output) == ""
        @test sr.output |> !eof
    end

    @testset begin
        sr = StreamReassembler(65000)
        push_substring!(sr, "a", 0)
        @test sr.cur_idx == 1
        @test read!(sr.output) == "a"
        @test sr.output |> !eof
    end

    @testset begin
        sr = StreamReassembler(65000)
        push_substring!(sr, "a", 0, true)
        @test sr.cur_idx == 1
        @test read!(sr.output) == "a"
        @test sr.output |> eof
    end

    @testset begin
        sr = StreamReassembler(65000)
        push_substring!(sr, "", 0, true)
        @test sr.cur_idx == 0
        @test read!(sr.output) == ""
        @test sr.output |> eof
    end
    
    @testset begin
        sr = StreamReassembler(65000)
        push_substring!(sr, "b", 0, true)
        @test sr.cur_idx == 1
        @test read!(sr.output) == "b"
        @test sr.output |> eof
    end
    
    @testset begin
        sr = StreamReassembler(65000)
        push_substring!(sr, "", 0)
        @test sr.cur_idx == 0
        @test read!(sr.output) == ""
        @test sr.output |> !eof
    end

    @testset begin
        sr = StreamReassembler(8)
        push_substring!(sr, "abcdefgh", 0)
        @test sr.cur_idx == 8
        @test read!(sr.output) == "abcdefgh"
        @test sr.output |> !eof
    end

    @testset begin
        sr = StreamReassembler(8)
        push_substring!(sr, "abcdefgh", 0, true)
        @test sr.cur_idx == 8
        @test read!(sr.output) == "abcdefgh"
        @test sr.output |> eof
    end

    @testset begin
        sr = StreamReassembler(8)
        push_substring!(sr, "abc", 0)
        @test sr.cur_idx == 3
        push_substring!(sr, "bcdefgh", 1, true)

        @test read!(sr.output) == "abcdefgh"
        @test sr.output |> eof
    end

    @testset begin
        sr = StreamReassembler(8)
        push_substring!(sr, "abc", 0)
        @test sr.cur_idx == 3
        @test sr.output |> !eof

        push_substring!(sr, "ghX", 6, true)
        @test sr.cur_idx == 3
        @test sr.output |> !eof

        push_substring!(sr, "cdefg", 2)
        @test sr.cur_idx == 8
        @test sr.output |> !eof

        @test read!(sr.output) == "abcdefgh"
        @test sr.output |> !eof
    end

    @testset begin
        sr = StreamReassembler(8)
        push_substring!(sr, "abc", 0)
        @test sr.cur_idx == 3
        @test sr.output |> !eof

        push_substring!(sr, "", 6)
        @test sr.cur_idx == 3
        @test sr.output |> !eof

        push_substring!(sr, "de", 3, true)
        @test sr.cur_idx == 5

        @test read!(sr.output) == "abcde"
        @test sr.output |> eof
    end
end