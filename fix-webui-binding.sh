#!/bin/bash

# Script to fix Web UI binding to 0.0.0.0
set -e

echo "🔧 Fixing Web UI binding to 0.0.0.0..."

# Check if container is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container is not running. Start it first with: docker-compose up -d"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(docker-compose ps -q ipfs)

echo "📝 Updating IPFS configuration..."

# Ensure API is bound to all interfaces
docker exec $CONTAINER_ID ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001

# Verify the configuration
echo "✅ Current API configuration:"
docker exec $CONTAINER_ID ipfs config Addresses.API

echo ""
echo "🔄 Restarting IPFS to apply changes..."
docker-compose restart

echo "⏳ Waiting for IPFS to restart..."
sleep 10

# Check if IPFS is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container failed to restart. Check logs with: docker-compose logs"
    exit 1
fi

echo ""
echo "✅ Web UI should now be accessible from all interfaces!"
echo ""
echo "🌐 Access URLs:"
echo "  - Web UI: http://0.0.0.0:5001/webui"
echo "  - API: http://0.0.0.0:5001"
echo "  - Gateway: http://0.0.0.0:8080"
echo ""
echo "💡 You can also access from external machines using your server's IP:"
echo "  - Web UI: http://YOUR_SERVER_IP:5001/webui"
echo "  - API: http://YOUR_SERVER_IP:5001"
echo "  - Gateway: http://YOUR_SERVER_IP:8080"