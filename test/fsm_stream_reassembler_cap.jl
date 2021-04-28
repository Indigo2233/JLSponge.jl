function main()
    let rs = StreamReassembler(2)
        push_substring(rs, "ab", 0)
        @assert rs.cur_idx == 2 "$(rs.cur_idx)"
        @assert read!(rs.output) == "ab"

        push_substring(rs, "cd", 2)
        @assert rs.cur_idx == 4
        @assert read!(rs.output) == "cd"
        
        push_substring(rs, "ef", 4)
        @assert rs.cur_idx == 6
        @assert read!(rs.output) == "ef"
    end
    let rs = StreamReassembler(2)
        push_substring(rs, "ab", 0)
        @assert rs.cur_idx == 2 "$(rs.cur_idx)"
        push_substring(rs, "cd", 2)
        
        @assert rs.cur_idx == 2 "$(rs.cur_idx)"
        @assert read!(rs.output) == "ab"
    
        push_substring(rs, "cd", 2)
        @assert rs.cur_idx == 4
        @assert read!(rs.output) == "cd"
    end
    let rs = StreamReassembler(1)
        push_substring(rs, "ab", 0)
        @assert rs.cur_idx == 1 "$(rs.cur_idx)"
        
        push_substring(rs, "ab", 0)
        @assert rs.cur_idx == 1 "$(rs.cur_idx)"
        
        @assert read!(rs.output) == "a"
    
        push_substring(rs, "abc", 0)
        @assert rs.cur_idx == 2 "$(rs.cur_idx)"
        @assert read!(rs.output) == "b"
        @assert rs.cur_idx == 2 "$(rs.cur_idx)"
    end
    
    let rs = StreamReassembler(3)
        for i in 0:3:99997
            seg = Char.(rand(1:125, 6)) |> string
            push_substring(rs, seg, i)
            @assert rs.cur_idx == i + 3
            @assert read!(rs.output) == SubString(seg, 1:3)
        end
    end
end
main()

