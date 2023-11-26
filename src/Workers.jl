module Workers

using FileIO
using Images

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
    file_name_no_ext = split(file_name, ".")[1]
    output_path = "shared/formatted/"*file_name_no_ext*".png"

    # Save the image as a PNG
    img = load(input_path)
    save(output_path, img)

    output_path
end

function resolution_handler( input_path::String )
    file_name = split(input_path, "/")[end]
    output_path = "shared/scaled/"*file_name

    target_resolution = (100, 100)

    img = load(input_path)
    resized_img = imresize(img, target_resolution)
    save(output_path, resized_img)

    output_path
end

function size_handler( input_path::String )
    file_name = split(input_path, "/")[end]
    output_path = "shared/output/"*file_name

    target_size = (30, 30)

    img = load(input_path)
    resized_img = center_crop(img, target_size)
    save(output_path, resized_img)

    output_path
end

function center_crop(img, new_size)
    size_diff = size(img) .- new_size
    offset = size_diff .÷ 2
    return img[offset[1]+1:offset[1]+new_size[1], offset[2]+1:offset[2]+new_size[2]]
end

end