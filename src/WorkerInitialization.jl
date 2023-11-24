module WorkerInitialization

using Distributed

export get_channels, get_workers

function add_type_workers(type::String)
    path = "ips/"*type
    ips = map(file -> readlines(path*"/$file")[1], readdir(path))
    addprocs(ips)
end

# These need to be defined at the module level
# Initializing them in a function will not work
format_workers = add_type_workers("format")
resolution_workers = add_type_workers("resolution")
size_workers = add_type_workers("size")
close_workers = () -> rmprocs(workers())
get_workers() = format_workers, resolution_workers, size_workers, close_workers


function get_channels()
    format_channel = RemoteChannel(()->Channel{Int}(32))
    resolution_channel = RemoteChannel(()->Channel{Int}(32))
    size_channel = RemoteChannel(()->Channel{Int}(32))

    result_channel = RemoteChannel(()->Channel{Int}(32))

    close_channels = () -> begin
        close(format_channel)
        close(resolution_channel)
        close(size_channel)
        close(result_channel)
    end

    return format_channel, resolution_channel, size_channel, result_channel, close_channels
end

end