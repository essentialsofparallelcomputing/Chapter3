#!/bin/sh
docker build --no-cache -t chapter3 .
#docker run -it --entrypoint /bin/bash chapter3
docker build --no-cache -f Dockerfile.Ubuntu20.04 -t chapter3 .
#docker run -it --entrypoint /bin/bash chapter3
docker build --no-cache -f Dockerfile.debian -t chapter3 .
#docker run -it --entrypoint /bin/bash chapter3
