#! /bin/bash

#########################################################################
# Script: docker-spotify.sh                                             #
# Version: 0.5.0                                                        #
#                                                                       #
# Description:                                                          #
# The script to start the syncomm/netflix container                     #
#                                                                       #
# Copyright (C) 2014, Gregory S. Hayes <ghayes@redhat.com>              #
#                                                                       #
# This program is free software; you can redistribute it and/or modify  #
# it under the terms of the GNU General Public License as published by  #
# the Free Software Foundation; either version 2 of the License, or     #
# (at your option) any later version.                                   #
#                                                                       #
# This program is distributed in the hope that it will be useful,       #
# but WITHOUT ANY WARRANTY; without even the implied warranty of        #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
# GNU General Public License for more details.                          #
#                                                                       #
# You should have received a copy of the GNU General Public License     #
# along with this program; if not, write to the                         #
# Free Software Foundation, Inc.,                                       #
# 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.             #
#                                                                       #
# modified by Timo Kramer <kontakt@timokramer.de>                       #
#                                                                       #
#########################################################################

# name of container to use
DOCKER_SPOTIFY='docker-spotify:latest'

# Set some colors
red='\e[0;31m'
lpurp='\e[1;35m'
yellow='\e[1;33m'
NC='\e[0m' # No Color

# Start the docker daemon
DAEMON_RUNNING=$(systemctl is-active docker.service &> /dev/null)
if [ $? -ne 0 ]; then
    echo -e "${lpurp}Starting docker daemon${NC}"
    su -c 'systemctl start docker' || exit 1
fi

# Get the X11 Cookie to pass
echo -e "${lpurp}Grabbing X11 Cookie of host${NC}" 
XCOOKIE=`xauth list | grep unix | cut -f2 -d"/" | tr -cd '\11\12\15\40-\176' | sed -e 's/  / /g'`

# Create the Pulseaudio Socket
if [ ! -e /tmp/.spotify-pulse-socket ];
then
    echo -e "${lpurp}Adding Pulseaudio socket at /tmp/.spotify-pulse-socket${NC}" 
    SPOTIFYSOCKET=`pactl load-module module-native-protocol-unix auth-anonymous=1 socket=/tmp/.spotify-pulse-socket`
fi

# Persistant cache and config 
VOLUME=spotify-data
EXIST=$(docker volume inspect $CONTAINER 2> /dev/null)

if [ $? -eq 1 ]; then
    echo -e "${lpurp}Creating Volume $VOLUME${NC}"
    docker volume create $CONTAINER
    echo -e "${lpurp}Container $VOLUME created${NC}"
fi

# Launch spotify container 
echo -e "${lpurp}Launching docker-spotify container${NC}" 
echo docker run --rm --name spotify \
  -e XCOOKIE=\'$XCOOKIE\' \
  --volume /tmp/.X11-unix/:/tmp/.X11-unix/ \
  --volume /tmp/.spotify-pulse-socket:/tmp/.spotify-pulse-socket \
  --volume $VOLUME:/home/spotify \
  -t $DOCKER_SPOTIFY | sh

# Clean up Pulseaudio socket
echo -e "${lpurp}Removing Pulseaudio socket at /tmp/.spotify-pulse-socket${NC}" 
pactl unload-module $SPOTIFYSOCKET

exit 0
