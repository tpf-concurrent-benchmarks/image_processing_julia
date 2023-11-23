using Distributed

amount_of_workers = workers().length()
workers1 = workers()[1:amount_of_workers-2]
workers2 = workers()[amount_of_workers-1:amount_of_workers]

println("Workers 1: $workers1")
println("Workers 2: $workers2")
println("Amount of workers: $amount_of_workers")

work1_channel = RemoteChannel(()->Channel{Int}(32))
work2_channel = RemoteChannel(()->Channel{Int}(32))
result_channel = RemoteChannel(()->Channel{Int}(32))


function worker_loop( in_channel::Channel, out_channel::Channel )
    println("Started")
    while true
        number = take!(in_channel)
        put!(out_channel, number + 1)
    end
end

# Worker 1 adds 1 to the number
@everywhere function worker1_loop(work_channel, result_channel)
    while true
        number = take!(work_channel)
        put!(result_channel, number + 2)
    end
end

# Worker 2 adds 2 to the number
@everywhere function worker2_loop(work_channel, result_channel)
    println("Worker 2")
    while true
        number = take!(work_channel)
        put!(result_channel, number + 2)
    end
end

# Start the workers
for p in workers1
    @spawnat p worker1_loop(work1_channel, work2_channel)
end

for p in workers2
    @spawnat p worker2_loop(work2_channel, result_channel)
end

# Send some work
println("Sending work")
for i in 1:10
    put!(work1_channel, i)
end

# Get the results

for i in 1:10
    println(take!(result_channel))
end

# Close the channels

close(work1_channel)
close(work2_channel)

