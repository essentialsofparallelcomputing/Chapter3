#!/bin/sh
docker build -f Dockerfile -t chapter3 .
docker run -it --entrypoint /bin/bash chapter3
