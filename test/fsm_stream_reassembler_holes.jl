using JLSponge
function main()
    let rs = StreamReassembler(65000) 
        push_substring(rs, "b", 1)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        
        @assert !eof(rs.output)
    end
    let rs = StreamReassembler(65000) 
        push_substring(rs, "b", 1)
        @assert rs.cur_idx == 0 
        push_substring(rs, "a", 0)
        @assert rs.cur_idx == 2    
        @assert read!(rs.output) == "ab"
        @assert !eof(rs.output)
    end

    let rs = StreamReassembler(65000) 
        push_substring(rs, "b", 1, true)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
        push_substring(rs, "a", 0)
        @assert rs.cur_idx == 2    
        @assert read!(rs.output) == "ab"
        @assert eof(rs.output)
    end

    let rs = StreamReassembler(65000) 
        push_substring(rs, "b", 1)
        push_substring(rs, "ab", 0)
    
        @assert rs.cur_idx == 2    
        @assert read!(rs.output) == "ab"
        @assert !eof(rs.output)
    end

    let rs = StreamReassembler(65000) 
        push_substring(rs, "b", 1)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
        push_substring(rs, "d", 3)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
        
        push_substring(rs, "c", 2)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
        
        push_substring(rs, "ab", 0)
    
        @assert rs.cur_idx == 4 
        @assert read!(rs.output) == "abcd"
        @assert !eof(rs.output)
    end

    let rs = StreamReassembler(65000) 
        push_substring(rs, "b", 1)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
        push_substring(rs, "d", 3)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
    
        
        push_substring(rs, "abc", 0)
    
        @assert rs.cur_idx == 4 
        @assert read!(rs.output) == "abcd"
        @assert !eof(rs.output)
    end
   
    let rs = StreamReassembler(65000) 
        push_substring(rs, "b", 1)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
        push_substring(rs, "d", 3)
        @assert rs.cur_idx == 0 
        @assert read!(rs.output) == ""
        @assert !eof(rs.output)
    
        push_substring(rs, "a", 0)
        @assert rs.cur_idx == 2
        @assert read!(rs.output) == "ab"
        @assert !eof(rs.output)
    
        push_substring(rs, "c", 2)
        @assert rs.cur_idx == 4
        @assert read!(rs.output) == "cd"
        @assert !eof(rs.output)
    
        push_substring(rs, "", 4, true)
    
        @assert rs.cur_idx == 4 
        @assert read!(rs.output) == ""
        @assert eof(rs.output)
    end

    
end
main()