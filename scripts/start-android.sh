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
