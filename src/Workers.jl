module Workers

export worker_loop, format_handler, resolution_handler, size_handler, stop_message

const stop_message::String = "STOP"

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


function format_handler( input_path::String )
    file_name = split(input_path, "/")[end]
    output_path = "shared/formatted/"*file_name
    output_path
end

function resolution_handler( input_path::String )
    file_name = split(input_path, "/")[end]
    output_path = "shared/scaled/"*file_name
    output_path
end
    
function size_handler( input_path::String )
    file_name = split(input_path, "/")[end]
    output_path = "shared/output/"*file_name
    output_path
end


end