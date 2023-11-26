using Distributed

include("WorkerInitialization.jl")
using .WorkerInitialization

@everywhere include("Workers.jl")
@everywhere using .Workers



function start_worker_stage( workers::Array, handler::Function, in_channel::RemoteChannel, out_channel::RemoteChannel )
    for p in workers
        remote_do( worker_loop, p, handler, in_channel, out_channel)
    end
end

function start_pipeline()
    println("Starting workers")
    format_channel, resolution_channel, size_channel, result_channel = get_channels()
    format_workers, resolution_workers, size_workers = get_workers()

    # Start Format workers
    start_worker_stage( format_workers, format_handler, format_channel, resolution_channel )
    
    # Start Resolution workers
    start_worker_stage( resolution_workers, resolution_handler, resolution_channel, size_channel )
    
    # Start Size workers
    start_worker_stage( size_workers, size_handler, size_channel, result_channel )

    return format_channel, result_channel
end

function send_work( work_channel::RemoteChannel )
    println("Sending work")

    total_work = 0
    input_dir = readdir("shared/input")

    for filename in input_dir
        file_path = "shared/input/"*filename
        put!(work_channel, file_path)
        total_work += 1
    end

    total_work
end

function await_results( result_channel::RemoteChannel, total_work::Int )
    println("Awaiting results")
    for i in 1:total_work
        _result = take!(result_channel)
    end
end

function stop_workers()
    println("Stopping workers")
    
    worker_groups = get_workers_channels()

    _stop_workers = (workers, channel) -> begin
        for p in workers
            put!(channel, stop_message)
        end
    end

    for (workers, channel) in worker_groups
        _stop_workers(workers, channel)
    end

end

    
function main()
    
    input_channel, result_channel = start_pipeline()
    
    total_work = send_work( input_channel )
    await_results( result_channel, total_work )

    stop_workers()
    close_pipeline()
end

main()