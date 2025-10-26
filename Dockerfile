FROM budtmo/docker-android:emulator_9.0

# The budtmo/docker-android image already includes:
# - Android emulator
# - x11vnc on port 5900 (built-in, no password)
# 
# We'll add noVNC web interface on port 6080

USER root

# Install websockify and noVNC
RUN apt-get update && apt-get install -y \
    python3-websockify \
    git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /opt/noVNC \
    && git clone https://github.com/novnc/noVNC.git /opt/noVNC \
    && git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify \
    && ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# Create startup script for noVNC (connects to budtmo's built-in VNC on port 5900)
RUN mkdir -p /home/androidusr/docker-android/mixins/scripts \
    && echo '#!/bin/bash' > /home/androidusr/docker-android/mixins/scripts/start-novnc.sh \
    && echo 'sleep 5' >> /home/androidusr/docker-android/mixins/scripts/start-novnc.sh \
    && echo '/opt/noVNC/utils/novnc_proxy --vnc localhost:5900 --listen 6080' >> /home/androidusr/docker-android/mixins/scripts/start-novnc.sh \
    && chmod +x /home/androidusr/docker-android/mixins/scripts/start-novnc.sh

# Expose noVNC port 6080
EXPOSE 6080
