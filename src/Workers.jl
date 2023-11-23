module Workers

export worker1_loop, worker2_loop, print_hello


function worker_loop(message_handler::Function, in_channel, out_channel)
    while true
        message = take!(in_channel)
        result = message_handler(message)
        put!(out_channel, result)
    end
end


# Worker 1 adds 1 to the number
function worker1_loop(work_channel, result_channel)
    worker_loop(work_channel, result_channel) do number
        number + 1
    end
end

# Worker 2 adds 2 to the number
function worker2_loop(work_channel, result_channel)
    worker_loop(work_channel, result_channel) do number
        number + 2
    end
end

end