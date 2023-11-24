module WorkerInitialization

using Distributed

export get_channels, get_workers, get_workers_channels, close_pipeline

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


# These RemoteChannels work similar to Queues
format_channel = RemoteChannel(()->Channel{Int}(32))
resolution_channel = RemoteChannel(()->Channel{Int}(32))
size_channel = RemoteChannel(()->Channel{Int}(32))
result_channel = RemoteChannel(()->Channel{Int}(32))

close_channels = () -> for chan in [format_channel, resolution_channel, size_channel, result_channel]
        close(chan)
end
get_channels() = format_channel, resolution_channel, size_channel, result_channel, close_channels

get_workers_channels() = [ (format_workers, format_channel), (resolution_workers, resolution_channel), (size_workers, size_channel) ]

function close_pipeline()
    close_channels()
    close_workers()
end

end