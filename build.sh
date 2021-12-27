#!/bin/sh

docker build --tag ttlchunker .


docker rmi -f $(docker images -q --filter label=stage=intermediate)
