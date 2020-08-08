#!/bin/sh
docker build -f Dockerfile.vnc -t chapter3 .
docker run -d -p 5901:5901 --entrypoint /bin/bash chapter3
