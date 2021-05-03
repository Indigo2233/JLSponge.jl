function main()
    let rs = StreamReassembler(1000)
        push_substring!(rs, "a", 0)
        push_substring!(rs, "ab", 0)

        @assert rs.cur_idx == 2
        @assert read!(rs.output) == "ab"
        @assert !eof(rs.output)
    end

    let rs = StreamReassembler(1000)
        push_substring!(rs, "a", 0)
        @assert read!(rs.output) == "a"

        push_substring!(rs, "ab", 0)

        @assert rs.cur_idx == 2
        @assert read!(rs.output) == "a"
    end
    let rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        @assert read!(rs.output) == ""

        push_substring!(rs, "ab", 0)

        @assert rs.cur_idx == 2
        @assert read!(rs.output) == "ab"

        @assert rs.unassembled_bytes == 0
    end

    let rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        @assert read!(rs.output) == ""
    
        push_substring!(rs, "bc", 1)
        @assert read!(rs.output) == ""
    
        @assert rs.cur_idx == 0
        @assert rs.unassembled_bytes == 2
    end

    let rs = StreamReassembler(1000)
        push_substring!(rs, "c", 2)
        @assert read!(rs.output) == ""
    
        push_substring!(rs, "bcd", 1)
        @assert read!(rs.output) == ""
    
        @assert rs.cur_idx == 0
        @assert rs.unassembled_bytes == 3
    end

    let rs = StreamReassembler(1000)
        push_substring!(rs, "b", 1)
        push_substring!(rs, "d", 3)
        @assert read!(rs.output) == ""
        
        push_substring!(rs, "bcde", 1)
        @assert read!(rs.output) == ""
    
        @assert rs.cur_idx == 0
        @assert rs.unassembled_bytes == 4
    end

    let rs = StreamReassembler(1000)
        push_substring!(rs, "c", 2)
        push_substring!(rs, "bcd", 1)
        @assert read!(rs.output) == ""
        @assert rs.cur_idx == 0
        @assert rs.unassembled_bytes == 3
        
        push_substring!(rs, "a", 0)
        @assert read!(rs.output) == "abcd"
    
        @assert rs.cur_idx == 4
        @assert rs.unassembled_bytes == 0
    end
    
    let rs = StreamReassembler(1000)
        push_substring!(rs, "bcd", 1)
        push_substring!(rs, "c", 2)
        @assert read!(rs.output) == ""
        @assert rs.cur_idx == 0
        @assert rs.unassembled_bytes == 3
        
        push_substring!(rs, "a", 0)
        @assert read!(rs.output) == "abcd"
    
        @assert rs.cur_idx == 4
        @assert rs.unassembled_bytes == 0
    end
        
end

main()

