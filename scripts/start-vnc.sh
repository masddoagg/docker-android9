#!/bin/bash

# Remove any existing lock files
rm -rf /tmp/.X*-lock /tmp/.X11-unix

# Start KasmVNC server
vncserver :1 -geometry ${VNC_RESOLUTION:-1280x720} -depth ${VNC_COL_DEPTH:-24} -localhost no
