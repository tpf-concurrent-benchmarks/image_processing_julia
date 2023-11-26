using Distributed

include("WorkerInitialization.jl")
using .WorkerInitialization

@everywhere include("Configs.jl")
@everywhere include("StatsLogger.jl")

@everywhere include("Workers.jl")
@everywhere using .Workers

@everywhere begin
    const config = Configs.Config("resources/config.json")
    StatsLogger.initialize(config.logger.ip, config.logger.port, config.logger.prefix)
end


function start_worker_stage( workers::Array, handler::Function, in_channel::RemoteChannel, out_channel::RemoteChannel, type="worker" )
    for (i, p) in enumerate(workers)
        remote_do( worker_loop, p, handler, in_channel, out_channel, string(type, "_", i) )
    end
end

function start_pipeline()
    println("Starting workers")
    format_channel, resolution_channel, size_channel, result_channel = get_channels()
    format_workers, resolution_workers, size_workers = get_workers()

    # Start Format workers
    start_worker_stage( format_workers, format_handler, format_channel, resolution_channel, "format_worker" )
    
    # Start Resolution workers
    start_worker_stage( resolution_workers, resolution_handler, resolution_channel, size_channel, "resolution_worker" )
    
    # Start Size workers
    start_worker_stage( size_workers, size_handler, size_channel, result_channel, "size_worker" )

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

function await_results(result_channel::RemoteChannel, send_work_task::Task)
    println("Awaiting results")
    consumed_tasks = 0

    while !istaskdone(send_work_task) || isready(result_channel)
        _result = take!(result_channel)
        consumed_tasks += 1
    end

    total_tasks = fetch(send_work_task)
    remaining_tasks = total_tasks - consumed_tasks

    for i in 1:remaining_tasks
        _result = take!(result_channel)
    end

    println("Received $total_tasks results")
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
    
    send_work_task = @async send_work( input_channel )
    await_results( result_channel, send_work_task )

    stop_workers()
    close_pipeline()
end


_, elapsed = StatsLogger.runAndMeasure(main, "completion_time")
println("Completed in $elapsed seconds")