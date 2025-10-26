#!/bin/bash

# The budtmo/docker-android image already handles Android emulator startup
# This script is kept for compatibility but the emulator is managed by the base image

echo "Android emulator is managed by budtmo/docker-android base image"
echo "Emulator should be accessible via ADB and the display"

# Keep the script running
tail -f /dev/null
