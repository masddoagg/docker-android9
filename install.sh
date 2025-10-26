#!/bin/bash

# Android 9 Docker Setup with KasmVNC - One-Click Installation
# This script sets up Android 9 in Docker with KasmVNC (no noVNC)

set -e  # Exit on any error

echo "🚀 Starting Android 9 Docker Setup with KasmVNC..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root for security reasons"
   exit 1
fi

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Update system
print_status "Updating system packages..."
sudo apt-get update -qq

# Install Docker if not present
if ! command_exists docker; then
    print_status "Installing Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    sudo usermod -aG docker $USER
    rm get-docker.sh
    print_success "Docker installed successfully"
else
    print_status "Docker is already installed"
fi

# Install Docker Compose if not present
if ! command_exists docker-compose; then
    print_status "Installing Docker Compose..."
    sudo apt-get install -y docker-compose
    print_success "Docker Compose installed successfully"
else
    print_status "Docker Compose is already installed"
fi

# Install additional dependencies
print_status "Installing additional dependencies..."
sudo apt-get install -y \
    curl \
    wget \
    unzip \
    git \
    build-essential \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    bridge-utils

# Create project directory
PROJECT_DIR="$HOME/android9-kasmvnc"
print_status "Creating project directory at $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Create Dockerfile
print_status "Creating Dockerfile..."
cat > Dockerfile << 'EOF'
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
    && wget -q https://osdn.net/frs/redir.php?m=acc&f=android-x86%2F71931%2Fandroid-x86_64-9.0-r2.iso -O android-x86_64-9.0-r2.iso

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
EOF

# Create scripts directory and files
print_status "Creating startup scripts..."
mkdir -p scripts

# Create Android startup script
cat > scripts/start-android.sh << 'EOF'
#!/bin/bash

# Start Android x86 in QEMU
cd /android

# Check if Android is already installed
if [ ! -f "android-installed.flag" ]; then
    echo "First time setup - installing Android..."
    # Start QEMU for installation
    qemu-system-x86_64 \
        -enable-kvm \
        -m 2048 \
        -smp 2 \
        -cpu host \
        -machine q35 \
        -device intel-hda \
        -device hda-duplex \
        -cdrom android-x86_64-9.0-r2.iso \
        -hda android.qcow2 \
        -boot d \
        -netdev user,id=net0 \
        -device e1000,netdev=net0 \
        -vnc :2 \
        -daemonize
    
    echo "Android installation started. Please connect to VNC to complete setup."
    echo "After installation, restart the container to boot from disk."
else
    echo "Starting Android from installed disk..."
    # Start QEMU from installed disk
    qemu-system-x86_64 \
        -enable-kvm \
        -m 2048 \
        -smp 2 \
        -cpu host \
        -machine q35 \
        -device intel-hda \
        -device hda-duplex \
        -hda android.qcow2 \
        -netdev user,id=net0 \
        -device e1000,netdev=net0 \
        -vnc :2 \
        -daemonize
fi
EOF

# Create VNC startup script
cat > scripts/start-vnc.sh << 'EOF'
#!/bin/bash

# Remove any existing lock files
rm -rf /tmp/.X*-lock /tmp/.X11-unix

# Start KasmVNC server
vncserver :1 -geometry 1024x768 -depth 24 -localhost no
EOF

# Create desktop setup script
cat > scripts/setup-desktop.sh << 'EOF'
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
EOF

# Create supervisor configuration
print_status "Creating supervisor configuration..."
cat > supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=root

[program:vnc]
command=/home/vnc/scripts/start-vnc.sh
user=vnc
autostart=true
autorestart=true
stdout_logfile=/var/log/vnc.log
stderr_logfile=/var/log/vnc.log

[program:desktop]
command=/home/vnc/scripts/setup-desktop.sh
user=vnc
autostart=true
autorestart=false
stdout_logfile=/var/log/desktop.log
stderr_logfile=/var/log/desktop.log
EOF

# Create docker-compose.yml
print_status "Creating docker-compose.yml..."
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  android9-kasmvnc:
    build: .
    container_name: android9-kasmvnc
    privileged: true
    ports:
      - "5901:5901"  # KasmVNC port
    volumes:
      - ./data:/data
      - /dev/kvm:/dev/kvm
    environment:
      - DISPLAY=:1
      - VNC_RESOLUTION=1024x768
      - VNC_COL_DEPTH=24
    devices:
      - /dev/kvm
    restart: unless-stopped
EOF

# Create data directory
mkdir -p data

# Make scripts executable
chmod +x scripts/*.sh

print_status "Building Docker image..."
if docker-compose build; then
    print_success "Docker image built successfully"
else
    print_error "Failed to build Docker image"
    exit 1
fi

print_status "Starting Android 9 container..."
if docker-compose up -d; then
    print_success "Container started successfully"
else
    print_error "Failed to start container"
    exit 1
fi

# Wait for services to start
print_status "Waiting for services to initialize..."
sleep 15

# Check if container is running
if docker-compose ps | grep -q "Up"; then
    print_success "Android 9 with KasmVNC is now running!"
    echo ""
    echo "📱 Access Information:"
    echo "• KasmVNC: Connect to localhost:5901 with VNC client"
    echo "• Password: vnc"
    echo "• Resolution: 1024x768"
    echo ""
    echo "🔧 Management Commands:"
    echo "• Stop: docker-compose down"
    echo "• Restart: docker-compose restart"
    echo "• Logs: docker-compose logs -f"
    echo "• Status: docker-compose ps"
    echo ""
    echo "📝 Note: First time setup requires manual Android installation via VNC"
else
    print_error "Container failed to start properly"
    print_status "Showing logs..."
    docker-compose logs
    exit 1
fi

print_success "Installation completed successfully! 🎉"
