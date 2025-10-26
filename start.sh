#!/bin/bash

# Start D-Bus
sudo service dbus start

# Start PulseAudio in background
pulseaudio --start --log-target=syslog

# Set display
export DISPLAY=:1

# Create KasmVNC config directory
mkdir -p ~/.vnc

# Create KasmVNC configuration
cat > ~/.vnc/kasmvnc.yaml << 'EOF'
desktop:
  resolution:
    width: 1280
    height: 720
  allow_resize: true

network:
  interface: all
  websocket_port: 8444
  use_ipv4: true
  use_ipv6: false

security:
  authentication:
    username: android
    password: android

logging:
  level: 30

encoding:
  max_frame_rate: 60
  rect_encoding_mode: 0
  jpeg_quality: 7
  webp_quality: 5

print:
  enabled: false
EOF

# Start KasmVNC server
vncserver :1 -select-de manual -SecurityTypes None -geometry 1280x720 -depth 24

# Wait for VNC to start
sleep 3

# Start window manager (fluxbox)
DISPLAY=:1 fluxbox &

# Wait for window manager
sleep 2

# Start Android Emulator with software rendering for container compatibility
cd $ANDROID_SDK_ROOT
DISPLAY=:1 ./emulator/emulator -avd android9_emulator \
    -no-audio \
    -gpu swiftshader_indirect \
    -no-snapshot \
    -wipe-data \
    -no-boot-anim \
    -netdelay none \
    -netspeed full \
    -verbose &

# Keep the script running
tail -f /dev/null
