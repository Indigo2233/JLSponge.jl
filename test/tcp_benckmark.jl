using JLSponge, DataStructures

function move_segments(x::TCPConnection, y::TCPConnection, segments::Vector{TCPSegment},
                       reorder::Bool)
    while x.segments_out |> !isempty
        push!(segments, dequeue!(x.segments_out))
    end
    if reorder
        for seg in Iterators.reverse(segments)
            segment_received!(y, seg)            
        end
    else
        for seg in segments
            segment_received!(y, seg)   
        end
    end
    empty!(segments)
end

function main(reorder::Bool)
    ## When len = 100 * 1024 * 4, the program will give infinite loop
    ## and stuck in `while !eof(inbound_stream(y))`

    len = 100 * 1024 * 3
    x, y = TCPConnection(;cap=65000), TCPConnection(;cap=65000)
    string_to_send = rand(UInt8(1):UInt8(127), len) |> pointer |> unsafe_string
    bytes_to_send = @view(string_to_send[1:end])
    connect!(x)
    end_input_stream!(y)
    x_closed = false
    string_reveived = IOBuffer()

    first_time = time_ns()
    while !eof(inbound_stream(y))
        while length(bytes_to_send) != 0 && remaining_outbound_capacity(x) != 0
            want = min(remaining_outbound_capacity(x), length(bytes_to_send))
            written = write!(x, @view(bytes_to_send[1:want]))
            (written == want) || error("want = $want, written = $written")
            bytes_to_send = @view(bytes_to_send[want+1:end])
        end

        if length(bytes_to_send) == 0 && !x_closed
            end_input_stream!(x)
            x_closed = true
        end

        segments = TCPSegment[]
        move_segments(x, y, segments, reorder)
        move_segments(y, x, segments, false)
        available_output = inbound_stream(y) |> buffer_size
        if available_output > 0
            write(string_reveived, read!(inbound_stream(y), available_output))
        end
        tick!(x, 1000)
        tick!(y, 1000)
    end

    (string_reveived |> take! != string_to_send) || error("strings sent vs. received don't match")
    final_time = time_ns()
    duration = final_time - first_time
    gigabits_per_second = len * 8.0 / duration

    println("CPU-limited throughput", 
        (reorder ? " with reordering: " : "                : "), 
        gigabits_per_second, " Gbit/s")

    while isactive(x) || isactive(y)
        while length(bytes_to_send) != 0 && remaining_outbound_capacity(x) != 0
            want = min(remaining_outbound_capacity(x), length(bytes_to_send))
            written = write!(x, @view(bytes_to_send[1:want]))
            (written == want) || error("want = $want, written = $written")
            bytes_to_send = @view(bytes_to_send[want+1:end])
        end

        if length(bytes_to_send) == 0 && !x_closed
            end_input_stream!(x)
            x_closed = true
        end

        segments = TCPSegment[]
        move_segments(x, y, segments, reorder)
        move_segments(y, x, segments, false)
        available_output = inbound_stream(y) |> buffer_size
        if available_output > 0
            write(string_reveived, read!(inbound_stream(y), available_output))
        end
        tick!(x, 1000)
        tick!(y, 1000)      
    end
end

# main(false)
# main(true)

"""

void move_segments(TCPConnection &x, TCPConnection &y, vector<TCPSegment> &segments, const bool reorder) {
    while (not x.segments_out().empty()) {
        segments.emplace_back(move(x.segments_out().front()));
        x.segments_out().pop();
    }
    if (reorder) {
        for (auto it = segments.rbegin(); it != segments.rend(); ++it) {
            y.segment_received(move(*it));
        }
    } else {
        for (auto it = segments.begin(); it != segments.end(); ++it) {
            y.segment_received(move(*it));
        }
    }
    segments.clear();
}

void main_loop(const bool reorder) {
    TCPConfig config;
    TCPConnection x{config}, y{config};

    string string_to_send(len, 'x');
    for (auto &ch : string_to_send) {
        ch = rand();
    }

    Buffer bytes_to_send{string(string_to_send)};
    x.connect();
    y.end_input_stream();

    bool x_closed = false;

    string string_received;
    string_received.reserve(len);

    const auto first_time = high_resolution_clock::now();

    auto loop = [&] {
        // write input into x
        while (bytes_to_send.size() and x.remaining_outbound_capacity()) {
            const auto want = min(x.remaining_outbound_capacity(), bytes_to_send.size());
            const auto written = x.write(string(bytes_to_send.str().substr(0, want)));
            if (want != written) {
                throw runtime_error("want = " + to_string(want) + ", written = " + to_string(written));
            }
            bytes_to_send.remove_prefix(written);
        }

        if (bytes_to_send.size() == 0 and not x_closed) {
            x.end_input_stream();
            x_closed = true;
        }

        // exchange segments between x and y but in reverse order
        vector<TCPSegment> segments;
        move_segments(x, y, segments, reorder);
        move_segments(y, x, segments, false);

        // read output from y
        const auto available_output = y.inbound_stream().buffer_size();
        if (available_output > 0) {
            string_received.append(y.inbound_stream().read(available_output));
        }

        // time passes
        x.tick(1000);
        y.tick(1000);
    };

    while (not y.inbound_stream().eof()) {
        loop();
    }

    if (string_received != string_to_send) {
        throw runtime_error("strings sent vs. received don't match");
    }

    const auto final_time = high_resolution_clock::now();

    const auto duration = duration_cast<nanoseconds>(final_time - first_time).count();

    const auto gigabits_per_second = len * 8.0 / double(duration);

    cout << fixed << setprecision(2);
    cout << "CPU-limited throughput" << (reorder ? " with reordering: " : "                : ") << gigabits_per_second
         << " Gbit/s\n";

    while (x.active() or y.active()) {
        loop();
    }
}

int main() {
    try {
        main_loop(false);
        main_loop(true);
    } catch (const exception &e) {
        cerr << e.what() << "\n";
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
"""