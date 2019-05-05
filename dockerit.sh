#!/bin/sh
docker build --no-cache -t chapter3 .
docker run -it --entrypoint /bin/bash chapter3
