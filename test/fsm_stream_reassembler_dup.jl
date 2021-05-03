x
function main() 
    let rs = StreamReassembler(65000)
        push_substring!(rs, "abcd", 0)
        @assert rs.cur_idx == 4
        @assert read!(rs.output) == "abcd"
        @assert !eof(rs.output)
    
        push_substring!(rs, "abcd", 0)
        @assert rs.cur_idx == 4
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    end 
    let rs = StreamReassembler(65000)
        push_substring!(rs, "abcd", 0)
        @assert rs.cur_idx == 4
        @assert read!(rs.output) == "abcd"
        @assert !eof(rs.output)
    
        push_substring!(rs, "abcd", 4)
        @assert rs.cur_idx == 8
        @assert read!(rs.output) == "abcd"
        @assert !eof(rs.output)
    
        push_substring!(rs, "abcd", 0)
        @assert rs.cur_idx == 8
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
        push_substring!(rs, "abcd", 4)
        @assert rs.cur_idx == 8
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)    
    end 

    let rs = StreamReassembler(65000)
        push_substring!(rs, "abcdefgh", 0)
        @assert rs.cur_idx == 8
        @assert read!(rs.output) == "abcdefgh"
        @assert !eof(rs.output)
        data = "abcdefgh"
        for _ in 1:1000
            st = rand(0:8)
            ed = rand(st:8)
            push_substring!(rs, @view(data[st+1:ed]), st)
            @assert rs.cur_idx == 8
            @assert read!(rs.output) == ""
            @assert !eof(rs.output)
        end
    end 
    
    let rs = StreamReassembler(65000)
        push_substring!(rs, "abcd", 0)
        @assert rs.cur_idx == 4
        @assert read!(rs.output) == "abcd"
        @assert !eof(rs.output)
    
        push_substring!(rs, "abcdef", 0)
        @assert rs.cur_idx == 6
        @assert read!(rs.output) == "ef"
        @assert !eof(rs.output)
    end 
        
end

main()
