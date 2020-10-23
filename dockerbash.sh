#!/bin/sh
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
docker run -it --gpus all -v $XSOCK:$XSOCK -v $XAUTH:$XAUTH -e XAUTHORITY=$XAUTH --entrypoint /bin/bash essentialsofparallelcomputing/chapter3
