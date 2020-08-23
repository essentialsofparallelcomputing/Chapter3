#!/bin/sh
CONTAINER_IMAGE_NAME=essentialsofparallelcomputing/chapter3
CONTAINER_USER=chapter3
CONTAINER_HOME=/home/$CONTAINER_USER
NAME_RANDOM_EXT=`LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6; echo`
NAME=chapter3-$NAME_RANDOM_EXT
PASSWORD_RANDOM=`LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 6; echo`
VOLUME_LIST="-v $HOME/.ssh:$CONTAINER_HOME/.ssh"
VOLUME_LIST="$VOLUME_LIST -v $HOME/.gitconfig:$CONTAINER_HOME/.gitconfig_host"
#VOLUME_LIST="$VOLUME_LIST -v x11vnc_project:$CONTAINER_HOME/project"
WEB_PORT=6080
VNC_PORT=5900
SSH_PORT=2222

docker run -d --init --rm \
  --name $NAME --hostname $NAME \
  --shm-size 2g \
  -p $WEB_PORT:6080 -p $VNC_PORT:5900 -p $SSH_PORT:22 \
  --env VNCPASS=$PASSWORD_RANDOM \
  --env RESOLUT=2560x1080 \
  --env HOST_UID= \
  --env DOCKER_LANG=en_US \
  --env DOCKER_TIMEZONE=America/Denver \
  $VOLUME_LIST \
  -w $CONTAINER_HOME/Chapter3 \
  --security-opt seccomp=unconfined --cap-add=SYS_PTRACE \
  $CONTAINER_IMAGE_NAME \
  "startvnc.sh >> $CONTAINER_HOME/.log/vnc.log"

if [ "$?" = "0" ]; then
  echo "USE web browser with URL:"
  echo "    http://localhost:$WEB_PORT/vnc.html?resize=downscale&autoconnect=1&password=$PASSWORD_RANDOM"
  echo ""
  echo "VNC Viewers"
  echo "   connect to localhost:$VNC_PORT with password $PASSWORD_RANDOM"
  echo ""
  echo "You can also log into the container using the command"
  echo "    ssh -X -p $SSH_PORT $CONTAINER_USER@localhost -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no"
  echo "with an authorized key in $HOME/.ssh/authorized_keys."

else
  echo "docker run failed with STATUS $?"
fi
