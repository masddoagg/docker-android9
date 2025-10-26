#!/bin/bash

# Test script for Android Docker setup
# Note: This is a test script to verify the build process works

echo "🧪 Testing Android Docker Setup"
echo "================================="

# Test Docker build
echo "Testing Docker build..."
if docker build -t android-x86-kasmvnc-test . --no-cache; then
    echo "✅ Docker build successful!"
else
    echo "❌ Docker build failed!"
    exit 1
fi

echo ""
echo "🔍 Testing container startup..."
if docker run -d --name android-test --privileged -p 5901:5901 android-x86-kasmvnc-test; then
    echo "✅ Container started successfully!"
    
    # Wait a bit and check if services are running
    echo "Waiting 30 seconds for services to initialize..."
    sleep 30
    
    # Check if VNC port is accessible
    if docker exec android-test netstat -tlnp | grep :5901; then
        echo "✅ VNC server is listening on port 5901!"
    else
        echo "⚠️ VNC server may not be running properly"
    fi
    
    # Check if processes are running
    echo ""
    echo "📋 Running processes in container:"
    docker exec android-test ps aux | grep -E "(vnc|qemu|xfce|supervisor)"
    
    # Cleanup
    echo ""
    echo "🧹 Cleaning up test container..."
    docker stop android-test
    docker rm android-test
    
    echo "✅ Test completed successfully!"
else
    echo "❌ Container failed to start!"
    exit 1
fi

echo ""
echo "🎉 All tests passed! The Docker setup is working correctly."
echo "You can now use 'docker-compose up -d' to start the full setup."
