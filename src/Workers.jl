module Workers

import JSON
using FileIO
using Images

export worker_loop, format_handler, resolution_handler, size_handler, stop_message

const stop_message::String = "STOP"


struct Config
    format::String
    resolution::Tuple{Int, Int}
    size::Tuple{Int, Int}

    function Config( config_path::String )
        data = JSON.parsefile(config_path)
        
        format = get(data, "format", "png")

        _resolution = get(data, "resolution", "150x150")
        resolution = Tuple(parse.(Int, split(_resolution, "x")))

        _size = get(data, "size", "50x50")
        size = Tuple(parse.(Int, split(_size, "x")))

        new(format, resolution, size)
    end
end

function worker_loop(message_handler::Function, in_channel, out_channel)

    config = Config("config.json")

    while true
        message = take!(in_channel)
        if message == stop_message
            break
        end
        result = message_handler(message, config)
        put!(out_channel, result)
    end
end

function format_handler( input_path::String, config::Config )
    file_name = split(input_path, "/")[end]
    file_name_no_ext = split(file_name, ".")[1]
    output_path = "shared/formatted/"*file_name_no_ext*"."*config.format

    # Save the image as a PNG
    img = load(input_path)
    save(output_path, img)

    output_path
end

function resolution_handler( input_path::String, config::Config )
    file_name = split(input_path, "/")[end]
    output_path = "shared/scaled/"*file_name

    img = load(input_path)
    resized_img = imresize(img, config.resolution)
    save(output_path, resized_img)

    output_path
end

function size_handler( input_path::String, config::Config )
    file_name = split(input_path, "/")[end]
    output_path = "shared/output/"*file_name

    img = load(input_path)
    resized_img = center_crop(img, config.size)
    save(output_path, resized_img)

    output_path
end

function center_crop(img, new_size)
    size_diff = size(img) .- new_size
    offset = size_diff .÷ 2
    return img[offset[1]+1:offset[1]+new_size[1], offset[2]+1:offset[2]+new_size[2]]
end

end