#!/bin/sh
docker build -f Dockerfile.Ubuntu20.04 -t essentialsofparallelcomputing/chapter3 .
XSOCK=/tmp/.X11-unix
XAUTH=/tmp/.docker.xauth
xauth nlist :0 | sed -e 's/^..../ffff/' | xauth -f $XAUTH nmerge -
#chmod 755 $XAUTH
docker run -it --gpus all -v $XSOCK:$XSOCK -v $XAUTH:$XAUTH -e XAUTHORITY=$XAUTH --entrypoint /bin/bash essentialsofparallelcomputing/chapter3
