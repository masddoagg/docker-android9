#!/bin/bash

# Installation script for Docker on Ubuntu/Debian systems

echo "=== Docker Installation Script ==="
echo "This script will install Docker and Docker Compose on your system."
read -p "Continue? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    exit 1
fi

# Update package index
echo "Updating package index..."
sudo apt update

# Install required packages
echo "Installing prerequisites..."
sudo apt install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
echo "Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Set up the stable repository
echo "Setting up Docker repository..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package index again
echo "Updating package index with Docker repository..."
sudo apt update

# Install Docker Engine
echo "Installing Docker Engine..."
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add your user to the docker group
echo "Adding user to docker group..."
sudo usermod -aG docker $USER

# Start Docker service
echo "Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker installation
echo "Verifying installation..."
sudo docker --version
sudo docker compose version

echo ""
echo "=== Installation Complete ==="
echo "Docker has been installed successfully!"
echo ""
echo "IMPORTANT: You need to log out and log back in (or restart your terminal)"
echo "for the group changes to take effect. Alternatively, run:"
echo "  newgrp docker"
echo ""
echo "After that, you can build the Android 9 container with:"
echo "  docker build -t android9-kasmvnc ."
echo "  docker-compose up -d"
