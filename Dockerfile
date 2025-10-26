FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Set display and VNC settings
ENV DISPLAY=:1
ENV VNC_PORT=5901
ENV VNC_RESOLUTION=1280x720
ENV VNC_COL_DEPTH=24

# Install base dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    unzip \
    openjdk-8-jdk \
    python3 \
    python3-pip \
    supervisor \
    xvfb \
    fluxbox \
    dbus-x11 \
    pulseaudio \
    sudo \
    libxrandr2 \
    libxtst6 \
    libxss1 \
    libasound2 \
    && rm -rf /var/lib/apt/lists/*

# Install KasmVNC
RUN wget https://github.com/kasmtech/KasmVNC/releases/download/v1.2.0/kasmvncserver_jammy_1.2.0_amd64.deb -O kasmvnc.deb \
    && apt-get update \
    && dpkg -i kasmvnc.deb || apt-get install -f -y \
    && rm kasmvnc.deb

# Set JAVA_HOME
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$PATH:$JAVA_HOME/bin

# Create user for VNC
RUN useradd -m -s /bin/bash android \
    && echo "android:android" | chpasswd \
    && usermod -aG sudo android

# Switch to android user
USER android
WORKDIR /home/android

# Download Android SDK
ENV ANDROID_SDK_ROOT=/home/android/android-sdk
ENV PATH=$PATH:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools:$ANDROID_SDK_ROOT/emulator

RUN mkdir -p $ANDROID_SDK_ROOT && \
    cd $ANDROID_SDK_ROOT && \
    wget -q https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip && \
    unzip commandlinetools-linux-9477386_latest.zip && \
    rm commandlinetools-linux-9477386_latest.zip && \
    mkdir -p cmdline-tools/latest && \
    mv cmdline-tools/* cmdline-tools/latest/ || true

# Accept licenses and install Android 9 system image
RUN yes | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager --licenses && \
    $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "platform-tools" "platforms;android-28" && \
    $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "system-images;android-28;google_apis;x86_64" && \
    $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager "emulator"

# Create Android Virtual Device (AVD)
RUN echo "no" | $ANDROID_SDK_ROOT/cmdline-tools/latest/bin/avdmanager create avd \
    -n android9_emulator \
    -k "system-images;android-28;google_apis;x86_64" \
    -d "pixel"

# Switch back to root for system configuration
USER root

# Create VNC password file for KasmVNC
RUN mkdir -p /home/android/.vnc && \
    echo "android" | vncpasswd -f > /home/android/.vnc/passwd && \
    chmod 600 /home/android/.vnc/passwd && \
    chown -R android:android /home/android/.vnc

# Create startup script
COPY start.sh /start.sh
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN chmod +x /start.sh

# Expose VNC port
EXPOSE 5901

# Set the user back to android
USER android
WORKDIR /home/android

CMD ["/start.sh"]
