#!/bin/bash

# Script to fix IPFS API access and CORS configuration
set -e

echo "🔧 Fixing IPFS API access and CORS configuration..."

# Check if container is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container is not running. Start it first with: docker-compose up -d"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(docker-compose ps -q ipfs)

echo "📝 Updating IPFS configuration..."

# Fix API binding to all interfaces (0.0.0.0 instead of 127.0.0.1)
echo "🔗 Setting API to bind to all interfaces..."
docker exec $CONTAINER_ID ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001

# Get the server's external IP (if available)
EXTERNAL_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ipinfo.io/ip 2>/dev/null || echo "YOUR_EXTERNAL_IP")

echo "🌐 Detected external IP: $EXTERNAL_IP"

# Update CORS configuration to allow access from various origins
echo "🔓 Configuring CORS for external access..."

# Set API CORS headers
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT", "DELETE", "OPTIONS"]'
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type", "X-Requested-With"]'
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials '["true"]'
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Expose-Headers '["Location"]'

# Also configure Gateway CORS
echo "🌐 Configuring Gateway CORS..."
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT", "DELETE", "OPTIONS"]'
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type", "X-Requested-With"]'
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Credentials '["true"]'
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Expose-Headers '["Location"]'

# Verify the configuration
echo ""
echo "✅ Current API configuration:"
docker exec $CONTAINER_ID ipfs config Addresses.API

echo ""
echo "✅ Current CORS configuration:"
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin

echo ""
echo "🔄 Restarting IPFS to apply changes..."
docker-compose restart

echo "⏳ Waiting for IPFS to restart..."
sleep 15

# Check if IPFS is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container failed to restart. Check logs with: docker-compose logs"
    exit 1
fi

# Wait a bit more for the daemon to fully start
sleep 5

echo ""
echo "✅ IPFS should now be accessible from all interfaces!"
echo ""
echo "🌐 Access URLs:"
echo "  - Web UI: http://$EXTERNAL_IP:5001/webui"
echo "  - API: http://$EXTERNAL_IP:5001"
echo "  - Gateway: http://$EXTERNAL_IP:8080"
echo ""
echo "🔍 Test API access:"
echo "  curl http://$EXTERNAL_IP:5001/api/v0/id"
echo ""
echo "📊 Check daemon status:"
docker exec $CONTAINER_ID ipfs id