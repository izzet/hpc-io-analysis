#!/bin/bash

name="${1:-hpc-io-analysis}"

docker build -t "$name-base:latest" -f Dockerfile.base .

for tool in darshan dftracer recorder; do
    docker build -t "$name-$tool:latest" -f "Dockerfile.$tool" .
done
