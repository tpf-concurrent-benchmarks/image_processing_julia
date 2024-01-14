#!/bin/bash

worker_types=("format" "resolution" "size")

for worker_type in "${worker_types[@]}"; do
    echo "Getting IPs for ${worker_type} workers"
    counter=1
    task_name="${worker_type}_worker"
    for ip in $(nslookup tasks.${task_name} | awk '/^Address:/ && NR > 2 {print $2}'); do
        echo "$ip" > "/ips/${worker_type}/ip_${counter}.txt"
        ((counter++))
    done
done