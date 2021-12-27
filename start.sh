#!/bin/sh

docker run --name "ttlchunker-running" -d -p 9101:9101 ttlchunker

docker ps

