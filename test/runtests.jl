using Test

include("common.jl")
include("byte_stream_test_harness.jl")

for test_file in readdir(@__DIR__)
    if test_file != "runtests.jl" && endswith(test_file, ".jl")
        include(test_file)
    end
end