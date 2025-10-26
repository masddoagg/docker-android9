#!/bin/bash

# Wait for VNC server to start
sleep 5

# Set DISPLAY
export DISPLAY=:1

# Start XFCE desktop
startxfce4 &

# Wait a bit then start Android
sleep 10
/home/vnc/scripts/start-android.sh
