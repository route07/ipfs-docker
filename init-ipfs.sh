#!/bin/bash

# IPFS Private Cluster Initialization Script
set -e

echo "🚀 Initializing IPFS Private Cluster Node..."

# Create necessary directories
mkdir -p ipfs-data
mkdir -p ipfs-config

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Start the IPFS container
echo "📦 Starting IPFS container..."
docker-compose up -d

# Wait for IPFS to be ready
echo "⏳ Waiting for IPFS to initialize..."
sleep 10

# Check if IPFS is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container failed to start. Check logs with: docker-compose logs"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(docker-compose ps -q ipfs)

# Initialize IPFS if not already done
echo "🔧 Initializing IPFS node..."
docker exec $CONTAINER_ID ipfs init --profile=server

# Configure IPFS for private cluster
echo "🔒 Configuring IPFS for private cluster..."

# Remove default bootstrap nodes
docker exec $CONTAINER_ID ipfs bootstrap rm --all

# Configure API and Gateway to be accessible
docker exec $CONTAINER_ID ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
docker exec $CONTAINER_ID ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080

# Ensure Web UI is accessible from all interfaces
docker exec $CONTAINER_ID ipfs config --json Addresses.API '"/ip4/0.0.0.0/tcp/5001"'

# Disable MDNS discovery for private cluster
docker exec $CONTAINER_ID ipfs config Discovery.MDNS.Enabled false

# Configure CORS for API
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT", "DELETE", "OPTIONS"]'
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type", "X-Requested-With"]'
docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Credentials '["true"]'

# Configure CORS for Gateway
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT", "DELETE", "OPTIONS"]'
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Headers '["Authorization", "Content-Type", "X-Requested-With"]'
docker exec $CONTAINER_ID ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Credentials '["true"]'

# Restart IPFS to apply configuration
echo "🔄 Restarting IPFS to apply configuration..."
docker-compose restart

# Wait for restart
sleep 5

# Get node information
echo "📊 Node Information:"
echo "===================="
NODE_ID=$(docker exec $CONTAINER_ID ipfs id -f="<id>")
echo "Node ID: $NODE_ID"
echo "API Address: http://localhost:5001"
echo "Gateway Address: http://localhost:8080"
echo "Swarm Address: /ip4/$(hostname -I | awk '{print $1}')/tcp/4001/ipfs/$NODE_ID"

echo ""
echo "✅ IPFS Private Cluster Node initialized successfully!"
echo ""
echo "🔗 Useful commands:"
echo "  - View logs: docker-compose logs -f"
echo "  - Stop node: docker-compose down"
echo "  - Restart node: docker-compose restart"
echo "  - Access API: curl http://localhost:5001/api/v0/id"
echo "  - Access Gateway: http://localhost:8080/ipfs/QmYourHashHere"
echo ""
echo "🌐 To add this node to other IPFS instances, use:"
echo "  ipfs bootstrap add /ip4/$(hostname -I | awk '{print $1}')/tcp/4001/ipfs/$NODE_ID"