#!/bin/sh
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
docker run -it --gpus all -v $XSOCK:$XSOCK -v $XAUTH:$XAUTH -e XAUTHORITY=$XAUTH \
	--entrypoint /bin/bash essentialsofparallelcomputing/chapter3
