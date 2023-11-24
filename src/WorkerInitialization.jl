
using Distributed

begin

function folder_ips(folder::String)
    path = "ips/"*folder
    dir = readdir(path)
    map(file -> readlines(path*"/$file")[1], dir)
end

format_ips = folder_ips("format")
format_workers = addprocs(format_ips)

resolution_ips = folder_ips("resolution")
resolution_workers = addprocs(resolution_ips)

size_ips = folder_ips("size")
size_workers = addprocs(size_ips)

end