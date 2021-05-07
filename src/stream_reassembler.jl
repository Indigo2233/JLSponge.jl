function push_substring!(sr::StreamReassembler, data::AbstractString, index::Int, eof_flg::Bool=false)
    end_of_str = index + length(data)
    if eof_flg
        sr.eof_idx = end_of_str
        (end_of_str == sr.cur_idx) && return reach_eof(sr)
    end
    (index >= sr.capacity + sr.cur_idx || end_of_str <= sr.cur_idx || isempty(data)) && return
    
    start_point = max(sr.cur_idx - index, 0)
    end_point = min(sr.cur_idx + sr.capacity - index, length(data))
    abs_idx = start_point == 0 ? index : sr.cur_idx
    data = data[(1 + start_point):end_point]

    if !isempty(sr)
        prev_it = lb = searchsortedfirst(sr.unassembled_strings, abs_idx)
        if prev_it != startof(sr.unassembled_strings)
            prev_it = regress((sr.unassembled_strings, prev_it))            
            k, v = deref((sr.unassembled_strings, prev_it))
            diff = k + length(v) - abs_idx
            if diff >= 0
                data = v * @view(data[1+min(end, diff):end])
                sr.unassembled_bytes -= length(v)
                abs_idx = k
            end
        end
        first_after = searchsortedafter(sr.unassembled_strings, abs_idx + length(data))
        if first_after != lb            
            k, v = deref((sr.unassembled_strings, lb))
            adv = advance((sr.unassembled_strings, lb))
            while true
                k, v = deref((sr.unassembled_strings, lb))
                sr.unassembled_bytes -= length(v)
                delete!((sr.unassembled_strings, lb))
                lb = adv
                (adv == first_after) && break
                adv = advance((sr.unassembled_strings, lb))
            end
            diff = abs_idx + length(data) - k
            (diff >= 0) && (data *= @view(v[1+min(end, diff):end]))
        end
    end
    sr.unassembled_strings[abs_idx] = data
    sr.unassembled_bytes += length(data)

    if !isempty(sr)
        bg = startof(sr.unassembled_strings)
        fst = deref((sr.unassembled_strings, bg))
        (fst[1] != sr.cur_idx) && return
        s_to_write = fst[2]
        sr.unassembled_bytes -= length(s_to_write)
        sr.cur_idx += write!(sr.output, s_to_write)
        delete!((sr.unassembled_strings, bg))
        (sr.eof_idx == sr.cur_idx) && reach_eof(sr)
    end
    return
end

@inline stream_out(sr::StreamReassembler) = sr.output

unassembled_bytes(sr::StreamReassembler) = sr.unassembled_bytes

Base.isempty(sr::StreamReassembler) = isempty(sr.unassembled_strings)

function reach_eof(sr::StreamReassembler)::Nothing
    end_input!(sr.output)
    sr.unassembled_bytes = 0
    empty!(sr.unassembled_strings)
    return nothing
end