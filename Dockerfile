FROM budtmo/docker-android:emulator_9.0

# The budtmo/docker-android image already includes:
# - Android emulator
# - x11vnc on port 5900 (no password by default)
# - noVNC web interface on port 6080
# 
# We'll add password protection and expose on port 5901 with user ms:ms

USER root

# Install x11vnc if not present and create password file
RUN apt-get update && apt-get install -y \
    x11vnc \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create VNC password file for user 'ms' with password 'ms'
RUN mkdir -p /root/.vnc \
    && x11vnc -storepasswd ms /root/.vnc/passwd \
    && chmod 600 /root/.vnc/passwd

# Modify the VNC startup to use password and port 5901
RUN mkdir -p /home/androidusr/docker-android/mixins/scripts \
    && echo '#!/bin/bash' > /home/androidusr/docker-android/mixins/scripts/vnc-with-password.sh \
    && echo 'x11vnc -display :1 -forever -shared -rfbport 5901 -rfbauth /root/.vnc/passwd' >> /home/androidusr/docker-android/mixins/scripts/vnc-with-password.sh \
    && chmod +x /home/androidusr/docker-android/mixins/scripts/vnc-with-password.sh

# Expose VNC port 5901
EXPOSE 5901
