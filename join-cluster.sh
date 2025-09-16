#!/bin/bash

# Script to join an existing IPFS private cluster
set -e

echo "🔗 Joining IPFS Private Cluster..."

# Default cluster node information (update these for your cluster)
CLUSTER_NODE_ID="12D3KooWPPN829Tton19NgLwrTvKfzKrYTXPv7ctvqPDfBhE87vB"
CLUSTER_IPV4="46.62.197.187"
CLUSTER_IPV6="2a01:4f9:c013:9177::1"

# Check if container is running
if ! sudo docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container is not running. Start it first with: sudo docker-compose up -d"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(sudo docker-compose ps -q ipfs)

echo "📝 Configuring node to join private cluster..."

# Remove all existing bootstrap nodes
echo "🗑️ Removing existing bootstrap nodes..."
sudo docker exec $CONTAINER_ID ipfs bootstrap rm --all

# Add cluster nodes as bootstrap peers
echo "🔗 Adding cluster nodes as bootstrap peers..."

# Add IPv4 bootstrap peer
echo "Adding IPv4 bootstrap peer: $CLUSTER_IPV4"
sudo docker exec $CONTAINER_ID ipfs bootstrap add /ip4/$CLUSTER_IPV4/tcp/4001/ipfs/$CLUSTER_NODE_ID

# Add IPv6 bootstrap peer (if available)
if [ "$CLUSTER_IPV6" != "" ]; then
    echo "Adding IPv6 bootstrap peer: $CLUSTER_IPV6"
    sudo docker exec $CONTAINER_ID ipfs bootstrap add /ip6/$CLUSTER_IPV6/tcp/4001/ipfs/$CLUSTER_NODE_ID
fi

# Verify bootstrap configuration
echo ""
echo "✅ Bootstrap nodes configured:"
sudo docker exec $CONTAINER_ID ipfs bootstrap list

# Restart IPFS to apply bootstrap configuration
echo ""
echo "🔄 Restarting IPFS to apply cluster configuration..."
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
echo "🔍 Checking cluster connection..."

# Check peer connections
echo "📊 Current peer connections:"
PEER_COUNT=$(sudo docker exec $CONTAINER_ID ipfs swarm peers | wc -l)
echo "Connected peers: $PEER_COUNT"

if [ "$PEER_COUNT" -gt 0 ]; then
    echo "✅ Successfully connected to cluster peers!"
    echo ""
    echo "Connected peers:"
    sudo docker exec $CONTAINER_ID ipfs swarm peers
else
    echo "⚠️ No peers connected yet. This may be normal if the cluster node is not running."
    echo "The node will automatically connect when the cluster node is available."
fi

# Get this node's information for adding to other cluster nodes
echo ""
echo "📋 This Node Information:"
NODE_ID=$(sudo docker exec $CONTAINER_ID ipfs id -f="<id>")
IPV4_IP=$(curl -4 -s ifconfig.me 2>/dev/null || echo "Unable to detect")
IPV6_IP=$(curl -6 -s ifconfig.me 2>/dev/null || echo "Unable to detect")

echo "Node ID: $NODE_ID"
echo "IPv4 IP: $IPV4_IP"
echo "IPv6 IP: $IPV6_IP"

echo ""
echo "🌐 Bootstrap addresses for other cluster nodes:"
if [ "$IPV4_IP" != "Unable to detect" ]; then
    echo "IPv4: /ip4/$IPV4_IP/tcp/4001/ipfs/$NODE_ID"
fi
if [ "$IPV6_IP" != "Unable to detect" ]; then
    echo "IPv6: /ip6/$IPV6_IP/tcp/4001/ipfs/$NODE_ID"
fi

echo ""
echo "🎉 Cluster join configuration complete!"
echo ""
echo "📝 To add this node to other cluster nodes, run:"
if [ "$IPV4_IP" != "Unable to detect" ]; then
    echo "  ipfs bootstrap add /ip4/$IPV4_IP/tcp/4001/ipfs/$NODE_ID"
fi
if [ "$IPV6_IP" != "Unable to detect" ]; then
    echo "  ipfs bootstrap add /ip6/$IPV6_IP/tcp/4001/ipfs/$NODE_ID"
fi
echo ""
echo "🔒 This node is now configured to join the private cluster!"
echo "💡 Run './check-ipfs-status.sh' to monitor cluster connectivity"