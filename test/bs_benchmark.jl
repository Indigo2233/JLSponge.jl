using JLSponge
using BenchmarkTools
function main()
    bs = ByteStream(3)
    JLSponge.write!(bs, "cb")
    for _ in 1:999999
        JLSponge.write!(bs, "abc")
        JLSponge.read!(bs, 1)
        JLSponge.write!(bs, "bca")
        JLSponge.read!(bs, 1)
        JLSponge.write!(bs, "cab")
        JLSponge.read!(bs, 3) == "abc"
        JLSponge.write!(bs, "bc")
    end
    return nothing
end

@time main()

