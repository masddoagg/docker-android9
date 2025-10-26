#!/bin/bash

# Remove any existing lock files
rm -rf /tmp/.X*-lock /tmp/.X11-unix

# Start KasmVNC server
vncserver :1 -geometry 1024x768 -depth 24 -localhost no
