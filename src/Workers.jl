module Workers

export worker_loop, format_handler, resolution_handler, size_handler, stop_message

const stop_message::Int = -1

function worker_loop(message_handler::Function, in_channel, out_channel)
    while true
        message = take!(in_channel)
        if message == stop_message
            break
        end
        result = message_handler(message)
        put!(out_channel, result)
    end
end


function format_handler( message::Int )
    message+1
end

function resolution_handler( message::Int )
    message+2
end
    
function size_handler( message::Int )
    message-3
end


end