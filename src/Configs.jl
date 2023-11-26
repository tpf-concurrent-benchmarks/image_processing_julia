module Configs

import JSON

export Config, WorkerConfig, LoggerConfig

struct WorkerConfig
    format::String
    resolution::Tuple{Int, Int}
    size::Tuple{Int, Int}

    function WorkerConfig( config_json::Dict)
        
        format = get(config_json, "format", "png")

        _resolution = get(config_json, "resolution", "150x150")
        resolution = Tuple(parse.(Int, split(_resolution, "x")))

        _size = get(config_json, "size", "50x50")
        size = Tuple(parse.(Int, split(_size, "x")))

        new(format, resolution, size)
    end
end

struct LoggerConfig
    ip::String
    port::Int

    function LoggerConfig( config_json::Dict )
        ip = get(config_json, "ip", "graphite")
        port = get(config_json, "port", 8125)
        
        new(ip, port)
    end
end

struct Config
    worker_config::WorkerConfig
    logger_config::LoggerConfig
    work_dir::String

    function Config( config_path::String )
        config_json = JSON.parsefile(config_path)
        
        worker_config = WorkerConfig(config_json["worker"])
        logger_config = LoggerConfig(config_json["logger"])
        work_dir = get(config_json, "work_dir", "shared/input")

        new(worker_config, logger_config, work_dir)
    end
end

end