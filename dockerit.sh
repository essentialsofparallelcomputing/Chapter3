#!/bin/sh
docker build --no-cache -f Dockerfile.Ubuntu20.04 -t chapter3 .
docker run -it --entrypoint /bin/bash chapter3
