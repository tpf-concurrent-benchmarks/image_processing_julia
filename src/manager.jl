include("initialize.jl")

using Distributed
@everywhere begin
	using Pkg
	Pkg.add("ProgressMeter")
	Pkg.instantiate()
	using ProgressMeter
end


@everywhere include("Workers.jl")

@everywhere using .Workers


function get_channels()
    work1_channel = RemoteChannel(()->Channel{Int}(32))
    work2_channel = RemoteChannel(()->Channel{Int}(32))
    result_channel = RemoteChannel(()->Channel{Int}(32))

    close_channels = () -> begin
        close(work1_channel)
        close(work2_channel)
        close(result_channel)
    end

    return work1_channel, work2_channel, result_channel, close_channels
end

function get_workers()
    amount_of_workers = length(workers())
    half = Int(ceil(amount_of_workers/2))
    workers1 = workers()[1:half]
    workers2 = workers()[half+1:amount_of_workers]

    return workers1, workers2
end

function workers_do( f::Function, workers::Array, args... )
    for p in workers
        remote_do(f, p, args...)
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
    
    work1_channel, work2_channel, result_channel, close_channels = get_channels()
    workers1, workers2 = get_workers()

    workers_do( worker1_loop, workers1, work1_channel, work2_channel )
    workers_do( worker2_loop, workers2, work2_channel, result_channel )
    
    send_work( work1_channel )

    await_results( result_channel )

    close_channels()
end

main()