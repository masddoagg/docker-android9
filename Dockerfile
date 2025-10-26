FROM ubuntu:18.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV NO_VNC_PORT=6901
ENV VNC_RESOLUTION=1024x768
ENV VNC_COL_DEPTH=24

# Install base packages
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    supervisor \
    net-tools \
    libnss3-dev \
    libatk-bridge2.0-dev \
    libdrm-dev \
    libxkbcommon-dev \
    libgtk-3-dev \
    libgbm-dev \
    libasound-dev \
    python3 \
    python3-pip \
    openjdk-8-jdk \
    qemu-kvm \
    qemu-utils \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils \
    virt-manager \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install KasmVNC
RUN wget -q https://github.com/kasmtech/KasmVNC/releases/download/v1.2.0/kasmvncserver_bionic_1.2.0_amd64.deb \
    && dpkg -i kasmvncserver_bionic_1.2.0_amd64.deb || true \
    && apt-get update && apt-get install -f -y \
    && rm kasmvncserver_bionic_1.2.0_amd64.deb

# Install Android x86
RUN mkdir -p /android && cd /android \
    && wget -q "https://osdn.net/frs/redir.php?m=acc&f=android-x86%2F71931%2Fandroid-x86_64-9.0-r2.iso" -O android-x86_64-9.0-r2.iso

# Create Android VM disk
RUN cd /android && qemu-img create -f qcow2 android.qcow2 8G

# Install XFCE4 desktop environment
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create VNC user
RUN useradd -m -s /bin/bash vnc \
    && echo 'vnc:vnc' | chpasswd \
    && adduser vnc sudo

# Setup KasmVNC for user
USER vnc
WORKDIR /home/vnc

# Configure KasmVNC
RUN mkdir -p /home/vnc/.vnc \
    && echo 'vnc' | vncpasswd -f > /home/vnc/.vnc/passwd \
    && chmod 600 /home/vnc/.vnc/passwd

# Create startup script for Android
RUN mkdir -p /home/vnc/scripts
COPY --chown=vnc:vnc scripts/ /home/vnc/scripts/
RUN chmod +x /home/vnc/scripts/*.sh

# Create supervisor configuration
USER root
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Expose VNC port
EXPOSE 5901

# Set working directory
WORKDIR /home/vnc

# Start services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
