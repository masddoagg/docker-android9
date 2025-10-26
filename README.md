# Android 9 Docker with KasmVNC Setup

This project provides a complete one-click installation of Android 9 running in Docker with KasmVNC (no noVNC), specifically designed for Codespaces and similar environments.

## 🚀 Quick Start

Run the single installation command:

```bash
curl -fsSL https://raw.githubusercontent.com/your-repo/android9-docker/main/install.sh | bash
```

Or manually:

```bash
chmod +x install.sh
./install.sh
```

## 📋 What This Does

The installation script will:

1. **Install Dependencies**
   - Docker and Docker Compose
   - QEMU/KVM virtualization tools
   - Required system packages

2. **Create Project Structure**
   - Dockerfile for Android 9 container
   - Docker Compose configuration
   - Startup scripts for services
   - Supervisor configuration

3. **Build and Start Container**
   - Ubuntu 18.04 base with KasmVNC
   - XFCE4 desktop environment  
   - Android x86 9.0 ISO
   - QEMU virtualization setup

4. **Configure Services**
   - KasmVNC server on port 5901
   - Android VM with hardware acceleration
   - Automatic service management

## 🔌 Access Information

After installation completes:

- **KasmVNC Access**: Connect to `localhost:5901` with any VNC client
- **Password**: `vnc`
- **Resolution**: 1024x768 (configurable)

## 📱 First Time Setup

1. Connect to VNC at `localhost:5901`
2. You'll see the XFCE desktop
3. Android installation will start automatically
4. Follow the Android setup wizard in the VM
5. After installation, restart the container

## 🛠 Management Commands

```bash
# Navigate to project directory
cd ~/android9-kasmvnc

# Stop the container
docker-compose down

# Start the container
docker-compose up -d

# Restart services
docker-compose restart

# View logs
docker-compose logs -f

# Check status
docker-compose ps

# Access container shell
docker-compose exec android9-kasmvnc bash

# Remove everything (clean uninstall)
docker-compose down -v
cd ~ && rm -rf android9-kasmvnc
```

## 🔧 Configuration Options

### Change VNC Resolution

Edit `docker-compose.yml`:

```yaml
environment:
  - VNC_RESOLUTION=1920x1080  # Change this
```

### Change VNC Password

Connect to container and run:

```bash
docker-compose exec android9-kasmvnc su - vnc
echo 'newpassword' | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd
docker-compose restart
```

### Allocate More RAM to Android

Edit `scripts/start-android.sh` and change:

```bash
-m 2048  # Change to -m 4096 for 4GB RAM
```

## 📊 System Requirements

- **RAM**: Minimum 4GB (8GB recommended)
- **CPU**: x64 with hardware virtualization support
- **Storage**: 10GB+ free space
- **OS**: Linux (Ubuntu 18.04+ recommended)

## 🐛 Troubleshooting

### Container Won't Start

```bash
# Check if KVM is available
ls -la /dev/kvm

# Check Docker status
sudo systemctl status docker

# View detailed logs
docker-compose logs android9-kasmvnc
```

### VNC Connection Issues

```bash
# Check if port is accessible
netstat -tlnp | grep 5901

# Restart VNC service
docker-compose exec android9-kasmvnc supervisorctl restart vnc
```

### Android VM Issues

```bash
# Check QEMU process
docker-compose exec android9-kasmvnc ps aux | grep qemu

# View VM display (VNC port :2)
# Connect VNC client to localhost:5902
```

### Performance Issues

1. **Enable KVM acceleration** (requires host support):
   ```bash
   # Check KVM support
   egrep -c '(vmx|svm)' /proc/cpuinfo
   ```

2. **Increase container resources**:
   Edit `docker-compose.yml` to add:
   ```yaml
   deploy:
     resources:
       limits:
         cpus: '2.0'
         memory: 4G
   ```

## 🔒 Security Notes

- VNC server runs without encryption by default
- Container runs in privileged mode for KVM access
- Default password is 'vnc' - change it for production use

## 📁 Project Structure

```
android9-kasmvnc/
├── install.sh              # Main installation script
├── Dockerfile              # Container definition
├── docker-compose.yml      # Service orchestration
├── supervisord.conf        # Process management
├── scripts/
│   ├── start-android.sh    # Android VM startup
│   ├── start-vnc.sh        # VNC server startup
│   └── setup-desktop.sh    # Desktop environment
└── data/                   # Persistent data
```

## 🆘 Support

If you encounter issues:

1. Check the logs: `docker-compose logs -f`
2. Verify system requirements
3. Ensure KVM/virtualization is enabled
4. Try rebuilding: `docker-compose down && docker-compose build --no-cache && docker-compose up -d`

## ⚡ Performance Tips

- Use SSD storage for better VM performance
- Allocate adequate RAM (4GB+ recommended)
- Enable hardware virtualization in BIOS/UEFI
- Close unnecessary applications to free resources

---

**Note**: This setup uses KasmVNC exclusively - noVNC is not included or used anywhere in the configuration.
