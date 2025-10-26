FROM budtmo/docker-android:emulator_9.0

# Switch to root for installations
USER root

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV VNC_RESOLUTION=1280x720
ENV VNC_COL_DEPTH=24

# Install TigerVNC and dependencies (simpler than KasmVNC)
RUN apt-get update && apt-get install -y \
    wget \
    supervisor \
    tigervnc-standalone-server \
    tigervnc-common \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create VNC user 'ms' with password 'ms'
RUN useradd -m -s /bin/bash ms \
    && echo 'ms:ms' | chpasswd \
    && usermod -aG sudo ms

# Configure VNC with password 'ms' (as root)
RUN mkdir -p /home/ms/.vnc \
    && echo 'ms' | vncpasswd -f > /home/ms/.vnc/passwd \
    && chmod 600 /home/ms/.vnc/passwd \
    && chown -R ms:ms /home/ms/.vnc

# Create startup script directory
RUN mkdir -p /home/ms/scripts \
    && chown -R ms:ms /home/ms/scripts

# Copy scripts
COPY --chown=ms:ms scripts/ /home/ms/scripts/
RUN chmod +x /home/ms/scripts/*.sh 2>/dev/null || true

# Create supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose VNC port
EXPOSE 5901

# Set working directory
WORKDIR /home/ms

# Start services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
