using Distributed

include("WorkerInitialization.jl")
using .WorkerInitialization

@everywhere include("Workers.jl")
@everywhere using .Workers



function workers_start( workers::Array, handler::Function, in_channel::RemoteChannel, out_channel::RemoteChannel )
    for p in workers
        remote_do( worker_loop, p, handler, in_channel, out_channel)
    end
end

function send_work( work_channel::RemoteChannel )
    println("Sending work")
    for i in 1:10
        put!(work_channel, i)
    end
end

function await_results( result_channel::RemoteChannel )
    println("Awaiting results")
    for i in 1:10
        println(take!(result_channel))
    end
end

    
function main()
    
    format_channel, resolution_channel, size_channel, result_channel, close_channels = get_channels()
    format_workers, resolution_workers, size_workers, close_workers = get_workers()

    # Start Format workers
    workers_start( format_workers, format_handler, format_channel, resolution_channel )
    
    # Start Resolution workers
    workers_start( resolution_workers, resolution_handler, resolution_channel, size_channel )
    
    # Start Size workers
    workers_start( size_workers, size_handler, size_channel, result_channel )
    
    send_work( format_channel )
    await_results( result_channel )

    close_channels()
    close_workers()
end

main()