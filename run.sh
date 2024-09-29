#!/bin/bash

benchmark="$1"
tool="$2"

container_name="hpc-io-analysis-$tool:latest"
log_dir="/var/log/$tool"

stop_container() {
    docker stop $(docker ps -q --filter ancestor=$container_name)
}

trap stop_container SIGINT

mkdir -p "$(pwd)/logs/$tool"

docker run \
    --rm \
    -v "$(pwd)/logs/$tool:/var/log/$tool" \
    -v "$(pwd)/scripts:/opt/scripts" \
    -w "/opt" \
    "$container_name" \
    sh -x -c ". scripts/analysis.sh && run_$benchmark $tool $log_dir"
