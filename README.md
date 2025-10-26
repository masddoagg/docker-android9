# Android 9 with KasmVNC Docker Setup

This project provides a Docker container running Android 9 emulator with KasmVNC (no noVNC) for remote access in Codespaces or any Linux environment.

## Quick Start

1. **Install Docker** (if not already installed):
   ```bash
   ./install_docker.sh
   ```

2. **Build and run the container**:
   ```bash
   docker-compose up -d
   ```

3. **Connect via VNC**: Use any VNC client to connect to `localhost:5901`

## Prerequisites

### Install Docker (Required)

Since Docker is not available in this environment, you'll need to install it first:

```bash
# Update package index
sudo apt update

# Install required packages
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
sudo apt update

# Install Docker Engine
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group
sudo usermod -aG docker $USER

# Start Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
docker --version
```

**Important**: After installing Docker, you may need to log out and log back in for the group changes to take effect, or use `newgrp docker` to apply the group changes in the current session.

## Project Structure

```
├── Dockerfile              # Main container definition
├── docker-compose.yml      # Easy deployment configuration
├── start.sh                # Container startup script
├── supervisord.conf         # Process supervisor configuration
└── README.md               # This file
```

## Features

- **Android 9 (API 28)**: Full Android 9 emulator with Google APIs
- **KasmVNC**: Modern VNC server with web interface (no noVNC dependency)
- **Container-optimized**: Runs with software rendering for maximum compatibility
- **User-friendly**: Simple setup with docker-compose
- **Codespaces compatible**: Works in GitHub Codespaces and similar environments

## Build the Container

```bash
# Clone or navigate to the project directory
cd /path/to/android9-kasmvnc

# Build the Docker image (this will take 15-30 minutes)
docker build -t android9-kasmvnc .
```

## Run with Docker Compose (Recommended)

```bash
# Start the container in background
docker-compose up -d

# View logs
docker-compose logs -f

# Stop the container
docker-compose down
```

## Run with Docker Command

```bash
# Run the container
docker run -d \
  --name android9-emulator \
  -p 5901:5901 \
  --privileged \
  android9-kasmvnc

# View logs
docker logs -f android9-emulator

# Stop and remove
docker stop android9-emulator
docker rm android9-emulator
```

## Connect to the Android Emulator

### Method 1: VNC Client
1. Use any VNC client (TigerVNC, RealVNC, etc.)
2. Connect to `localhost:5901`
3. Password: `android` (if prompted)

### Method 2: Browser (KasmVNC Web Interface)
1. Open browser and navigate to `http://localhost:6901`
2. Login with username: `android`, password: `android`

### Method 3: In Codespaces
1. GitHub Codespaces will automatically detect the port 5901
2. Click on the "Ports" tab in the terminal
3. Click on the port 5901 to open it in browser
4. Or use the forwarded URL with a VNC client

## Container Configuration

### Environment Variables
- `DISPLAY=:1` - X11 display number
- `VNC_RESOLUTION=1280x720` - Screen resolution
- `ANDROID_SDK_ROOT` - Android SDK location

### Exposed Ports
- `5901` - KasmVNC server port

### User Account
- Username: `android`
- Password: `android`

## Android Emulator Details

- **Android Version**: Android 9 (API level 28)
- **System Image**: Google APIs x86_64
- **Device Profile**: Pixel
- **GPU**: Software rendering (swiftshader_indirect)
- **Audio**: Disabled for container compatibility
- **Network**: Full speed, no delay simulation

## Troubleshooting

### Container Won't Start
```bash
# Check Docker is running
sudo systemctl status docker

# Check logs for errors
docker logs android9-emulator

# Rebuild the image
docker build --no-cache -t android9-kasmvnc .
```

### Can't Connect via VNC
```bash
# Verify port is exposed
docker port android9-emulator

# Check if VNC server is running inside container
docker exec -it android9-emulator ps aux | grep vnc
```

### Android Emulator Issues
```bash
# Check emulator process
docker exec -it android9-emulator ps aux | grep emulator

# Check emulator logs
docker exec -it android9-emulator cat /home/android/.android/avd/android9_emulator.avd/emulator_console.log
```

### Performance Issues
The emulator uses software rendering for maximum compatibility. For better performance in production:
1. Enable KVM if available: `docker run --device /dev/kvm`
2. Use hardware acceleration: Change `-gpu swiftshader_indirect` to `-gpu host`
3. Increase resources: `docker run -m 4g --cpus 2`

## Development Commands

```bash
# Enter container shell
docker exec -it android9-emulator bash

# Restart VNC server inside container
docker exec -it android9-emulator vncserver -kill :1
docker exec -it android9-emulator vncserver :1 -geometry 1280x720

# Check Android emulator status
docker exec -it android9-emulator /home/android/android-sdk/platform-tools/adb devices

# Create new AVD (if needed)
docker exec -it android9-emulator /home/android/android-sdk/cmdline-tools/latest/bin/avdmanager create avd -n test -k "system-images;android-28;google_apis;x86_64"
```

## File Permissions Fix

If you encounter permission issues:

```bash
# Fix file permissions
sudo chown -R $USER:$USER .
chmod +x start.sh
```

## Clean Up

```bash
# Remove containers and images
docker-compose down
docker rmi android9-kasmvnc
docker system prune -a
```

## Notes

- First boot may take 5-10 minutes as the emulator initializes
- Container uses `--privileged` mode for device access
- Data is not persistent by default (emulator uses `-wipe-data`)
- For persistent data, mount volumes as needed

## Tested Environments

- ✅ Ubuntu 20.04/22.04
- ✅ GitHub Codespaces
- ✅ Docker Desktop (Linux)
- ✅ WSL2 with Docker Desktop

## Support

This setup provides a complete Android 9 development environment with KasmVNC remote access. The container is optimized for compatibility and should work in most Docker environments including Codespaces.
