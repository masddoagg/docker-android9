FROM budtmo/docker-android:emulator_9.0

# The budtmo/docker-android image already includes:
# - Android emulator
# - x11vnc on port 5900 (no password by default)
# 
# We'll add noVNC web interface on port 6080 with password ms:ms

USER root

# Install x11vnc, websockify, and noVNC
RUN apt-get update && apt-get install -y \
    x11vnc \
    python3-websockify \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /opt/noVNC \
    && git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Create VNC password file for user 'ms' with password 'ms'
RUN mkdir -p /root/.vnc \
    && x11vnc -storepasswd ms /root/.vnc/passwd \
    && chmod 600 /root/.vnc/passwd

# Create startup script for VNC with password on port 5901
RUN mkdir -p /home/androidusr/docker-android/mixins/scripts \
    && echo '#!/bin/bash' > /home/androidusr/docker-android/mixins/scripts/vnc-with-password.sh \
    && echo 'x11vnc -display :1 -forever -shared -rfbport 5901 -rfbauth /root/.vnc/passwd &' >> /home/androidusr/docker-android/mixins/scripts/vnc-with-password.sh \
    && echo 'sleep 2' >> /home/androidusr/docker-android/mixins/scripts/vnc-with-password.sh \
    && echo '/opt/noVNC/utils/novnc_proxy --vnc localhost:5901 --listen 6080' >> /home/androidusr/docker-android/mixins/scripts/vnc-with-password.sh \
    && chmod +x /home/androidusr/docker-android/mixins/scripts/vnc-with-password.sh

# Expose VNC port 5901 and noVNC port 6080
EXPOSE 5901 6080
