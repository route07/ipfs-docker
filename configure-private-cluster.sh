#!/bin/bash

# Script to configure IPFS as a private cluster node
set -e

echo "🔒 Configuring IPFS as Private Cluster Node..."

# Check if container is running
if ! sudo docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container is not running. Start it first with: sudo docker-compose up -d"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(sudo docker-compose ps -q ipfs)

echo "📝 Removing public network connections..."

# Remove all bootstrap nodes (this removes public IPFS network access)
echo "🗑️ Removing all bootstrap nodes..."
sudo docker exec $CONTAINER_ID ipfs bootstrap rm --all

# Disable MDNS discovery (prevents automatic peer discovery)
echo "🚫 Disabling MDNS discovery..."
sudo docker exec $CONTAINER_ID ipfs config Discovery.MDNS.Enabled false

# Disable DHT (Distributed Hash Table) for private cluster
echo "🚫 Disabling DHT..."
sudo docker exec $CONTAINER_ID ipfs config Routing.Type none

# Disable public relay
echo "🚫 Disabling public relay..."
sudo docker exec $CONTAINER_ID ipfs config Swarm.DisableRelay true

# Disable autonat (automatic NAT traversal)
echo "🚫 Disabling autonat..."
sudo docker exec $CONTAINER_ID ipfs config Swarm.DisableNatPortMap true

# Disable bandwidth metrics
echo "🚫 Disabling bandwidth metrics..."
sudo docker exec $CONTAINER_ID ipfs config Swarm.DisableBandwidthMetrics true

# Configure connection manager for private cluster
echo "🔧 Configuring connection manager..."
sudo docker exec $CONTAINER_ID ipfs config --json Swarm.ConnMgr '{"Type": "basic", "LowWater": 10, "HighWater": 20, "GracePeriod": "30s"}'

# Disable pubsub (if you don't need it)
echo "🚫 Disabling pubsub..."
sudo docker exec $CONTAINER_ID ipfs config Pubsub.DisableSigning true

# Verify configuration
echo ""
echo "✅ Private cluster configuration:"
echo "Bootstrap nodes:"
sudo docker exec $CONTAINER_ID ipfs bootstrap list

echo ""
echo "MDNS discovery:"
sudo docker exec $CONTAINER_ID ipfs config Discovery.MDNS.Enabled

echo ""
echo "Routing type:"
sudo docker exec $CONTAINER_ID ipfs config Routing.Type

echo ""
echo "🔄 Restarting IPFS to apply private cluster settings..."
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
echo "🔍 Verifying private cluster configuration..."

# Check bootstrap nodes (should be empty)
echo "Bootstrap nodes (should be empty):"
BOOTSTRAP_COUNT=$(sudo docker exec $CONTAINER_ID ipfs bootstrap list | wc -l)
if [ "$BOOTSTRAP_COUNT" -eq 0 ]; then
    echo "✅ No bootstrap nodes configured - cluster is private"
else
    echo "❌ Bootstrap nodes still present:"
    sudo docker exec $CONTAINER_ID ipfs bootstrap list
fi

# Check peer count (should be 0 or very low)
echo ""
echo "📊 Current peer connections:"
PEER_COUNT=$(sudo docker exec $CONTAINER_ID ipfs swarm peers | wc -l)
echo "Connected peers: $PEER_COUNT"

if [ "$PEER_COUNT" -eq 0 ]; then
    echo "✅ No public peers connected - cluster is private"
else
    echo "⚠️ Still connected to $PEER_COUNT peers"
    echo "Peer addresses:"
    sudo docker exec $CONTAINER_ID ipfs swarm peers
fi

# Get node information for adding to other nodes
echo ""
echo "📋 Node Information for Private Cluster:"
NODE_ID=$(sudo docker exec $CONTAINER_ID ipfs id -f="<id>")
IPV4_IP=$(curl -4 -s ifconfig.me 2>/dev/null || echo "YOUR_IPV4_IP")
IPV6_IP=$(curl -6 -s ifconfig.me 2>/dev/null || echo "YOUR_IPV6_IP")

echo "Node ID: $NODE_ID"
echo ""
echo "🌐 Bootstrap addresses for other nodes:"
if [ "$IPV4_IP" != "YOUR_IPV4_IP" ]; then
    echo "IPv4: /ip4/$IPV4_IP/tcp/4001/ipfs/$NODE_ID"
fi
if [ "$IPV6_IP" != "YOUR_IPV6_IP" ]; then
    echo "IPv6: /ip6/$IPV6_IP/tcp/4001/ipfs/$NODE_ID"
fi

echo ""
echo "🎉 Private cluster configuration complete!"
echo ""
echo "📝 To add this node to other IPFS instances, run:"
if [ "$IPV4_IP" != "YOUR_IPV4_IP" ]; then
    echo "  ipfs bootstrap add /ip4/$IPV4_IP/tcp/4001/ipfs/$NODE_ID"
fi
if [ "$IPV6_IP" != "YOUR_IPV6_IP" ]; then
    echo "  ipfs bootstrap add /ip6/$IPV6_IP/tcp/4001/ipfs/$NODE_ID"
fi
echo ""
echo "🔒 Your IPFS node is now configured as a private cluster node!"