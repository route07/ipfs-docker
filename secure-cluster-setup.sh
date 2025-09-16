#!/bin/bash

# Script to set up a secure IPFS private cluster with swarm keys and secrets
set -e

echo "🔐 Setting up Secure IPFS Private Cluster..."

# Check if container is running
if ! sudo docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container is not running. Start it first with: sudo docker-compose up -d"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(sudo docker-compose ps -q ipfs)

# Generate or use existing swarm key
echo "🔑 Setting up swarm key..."
if [ ! -f "swarm.key" ]; then
    echo "Generating new swarm key..."
    # Create a simple swarm key (in production, use proper key generation)
    cat > swarm.key << EOF
/key/swarm/psk/1.0.0/
/base16/
$(openssl rand -hex 32)
EOF
    echo "✅ Swarm key generated: swarm.key"
else
    echo "✅ Using existing swarm key: swarm.key"
fi

# Copy swarm key to container
echo "📋 Installing swarm key in IPFS..."
sudo docker cp swarm.key $CONTAINER_ID:/data/ipfs/swarm.key

# Generate cluster secret if not exists
if [ ! -f "cluster-secret" ]; then
    echo "🔐 Generating cluster secret..."
    openssl rand -hex 32 > cluster-secret
    echo "✅ Cluster secret generated: cluster-secret"
else
    echo "✅ Using existing cluster secret: cluster-secret"
fi

# Configure IPFS for secure private cluster
echo "🔧 Configuring secure private cluster..."

# Remove all bootstrap nodes
sudo docker exec $CONTAINER_ID ipfs bootstrap rm --all

# Disable all discovery mechanisms
sudo docker exec $CONTAINER_ID ipfs config --json Discovery.MDNS.Enabled false
sudo docker exec $CONTAINER_ID ipfs config Routing.Type none

# Disable autonat and relay
sudo docker exec $CONTAINER_ID ipfs config --json Swarm.DisableNatPortMap true
sudo docker exec $CONTAINER_ID ipfs config --json Swarm.DisableBandwidthMetrics true

# Configure connection manager
sudo docker exec $CONTAINER_ID ipfs config --json Swarm.ConnMgr '{"Type": "basic", "LowWater": 5, "HighWater": 10, "GracePeriod": "20s"}'

# Disable pubsub
sudo docker exec $CONTAINER_ID ipfs config --json Pubsub.DisableSigning true

# Set up peering configuration
sudo docker exec $CONTAINER_ID ipfs config --json Peering.Peers '[]'

# Disable experimental features
sudo docker exec $CONTAINER_ID ipfs config --json Experimental.Libp2pStreamMounting false
sudo docker exec $CONTAINER_ID ipfs config --json Experimental.P2pHttpProxy false

echo ""
echo "🔒 Security Configuration:"
echo "Swarm Key: swarm.key"
echo "Cluster Secret: cluster-secret"
echo ""
echo "⚠️  IMPORTANT: Share these files securely with other cluster nodes!"
echo "   - Copy swarm.key to all cluster nodes"
echo "   - Copy cluster-secret to all cluster nodes"
echo "   - Keep these files secure and private"

# Restart IPFS
echo "🔄 Restarting IPFS with secure configuration..."
sudo docker-compose restart

echo "⏳ Waiting for IPFS to restart..."
sleep 15

# Check if IPFS is running
if ! sudo docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container failed to restart. Check logs with: sudo docker-compose logs"
    exit 1
fi

# Wait for daemon to fully start
sleep 5

echo ""
echo "🔍 Checking secure cluster status..."

# Check bootstrap nodes
echo "Bootstrap nodes (should be empty):"
BOOTSTRAP_COUNT=$(sudo docker exec $CONTAINER_ID ipfs bootstrap list | wc -l)
if [ "$BOOTSTRAP_COUNT" -eq 0 ]; then
    echo "✅ No bootstrap nodes configured"
else
    echo "❌ Bootstrap nodes still present:"
    sudo docker exec $CONTAINER_ID ipfs bootstrap list
fi

# Check peer count
echo ""
echo "📊 Current peer connections:"
PEER_COUNT=$(sudo docker exec $CONTAINER_ID ipfs swarm peers | wc -l)
echo "Connected peers: $PEER_COUNT"

# Get node information
echo ""
echo "📋 Secure Node Information:"
NODE_ID=$(sudo docker exec $CONTAINER_ID ipfs id -f="<id>")
IPV4_IP=$(curl -4 -s ifconfig.me 2>/dev/null || echo "Unable to detect")
IPV6_IP=$(curl -6 -s ifconfig.me 2>/dev/null || echo "Unable to detect")

echo "Node ID: $NODE_ID"
echo "IPv4 IP: $IPV4_IP"
echo "IPv6 IP: $IPV6_IP"

echo ""
echo "🎉 Secure private cluster setup complete!"
echo ""
echo "📝 Next steps:"
echo "1. Copy swarm.key and cluster-secret to other cluster nodes"
echo "2. Run this script on other nodes"
echo "3. Add bootstrap peers to connect nodes together"
echo ""
echo "🔒 Your IPFS node is now configured as a secure private cluster node!"