#!/bin/bash

# Script to properly set up CORS for IPFS
set -e

echo "🔓 Setting up CORS for IPFS..."

# Check if container is running
if ! sudo docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container is not running. Start it first with: sudo docker-compose up -d"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(sudo docker-compose ps -q ipfs)

echo "📝 Configuring CORS headers..."

# Configure API CORS
echo "🔧 Setting API CORS headers..."
sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT", "DELETE", "OPTIONS"]'
sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type", "X-Requested-With"]'
sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials '["true"]'
sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Expose-Headers '["Location"]'

# Configure Gateway CORS
echo "🌐 Setting Gateway CORS headers..."
sudo docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
sudo docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT", "DELETE", "OPTIONS"]'
sudo docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type", "X-Requested-With"]'
sudo docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Credentials '["true"]'
sudo docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Expose-Headers '["Location"]'

echo ""
echo "✅ CORS configuration completed!"
echo ""
echo "🔄 Restarting IPFS to apply CORS changes..."
sudo docker-compose restart

echo "⏳ Waiting for IPFS to restart..."
sleep 10

# Verify CORS configuration
echo ""
echo "🔍 Verifying CORS configuration..."
if sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin 2>/dev/null; then
    echo "✅ API CORS configured successfully"
    sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin
else
    echo "❌ API CORS configuration failed"
fi

if sudo docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Origin 2>/dev/null; then
    echo "✅ Gateway CORS configured successfully"
    sudo docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Origin
else
    echo "❌ Gateway CORS configuration failed"
fi

echo ""
echo "🎉 CORS setup complete! The Web UI should now work from external IPs."