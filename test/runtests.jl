using Test
using JLSponge

include("byte_stream_test_harness.jl")

for test_file in readdir(@__DIR__)
    if test_file != "runtests.jl"
        include(test_file)
    end
end