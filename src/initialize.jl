using Distributed

begin
    ips_folder = readdir("ips")
    ips = map(file -> readlines("ips/$file")[1], ips_folder)

    addprocs(ips)
end