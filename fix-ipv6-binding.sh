#!/bin/bash

# Script to fix IPv6 binding for IPFS
set -e

echo "🔧 Fixing IPv6 binding for IPFS..."

# Check if container is running
if ! docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container is not running. Start it first with: docker-compose up -d"
    exit 1
fi

# Get the container ID
CONTAINER_ID=$(docker-compose ps -q ipfs)

echo "📝 Updating IPFS configuration for IPv6..."

# Configure API to bind to all IPv4 and IPv6 interfaces
echo "🔗 Setting API to bind to all interfaces (IPv4 and IPv6)..."
docker exec $CONTAINER_ID ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
docker exec $CONTAINER_ID ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080

# Also add IPv6 binding
echo "🌐 Adding IPv6 binding..."
docker exec $CONTAINER_ID ipfs config --json Addresses.API '["/ip4/0.0.0.0/tcp/5001", "/ip6/::/tcp/5001"]'
docker exec $CONTAINER_ID ipfs config --json Addresses.Gateway '["/ip4/0.0.0.0/tcp/8080", "/ip6/::/tcp/8080"]'

# Get IPv4 external IP
echo "🔍 Detecting IPv4 external IP..."
IPV4_IP=$(curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s ipinfo.io/ip 2>/dev/null || echo "Unable to detect")

# Get IPv6 external IP
echo "🔍 Detecting IPv6 external IP..."
IPV6_IP=$(curl -6 -s ifconfig.me 2>/dev/null || curl -6 -s ipinfo.io/ip 2>/dev/null || echo "Unable to detect")

echo ""
echo "🌍 Detected IPs:"
echo "  IPv4: $IPV4_IP"
echo "  IPv6: $IPV6_IP"

# Verify the configuration
echo ""
echo "✅ Current API configuration:"
docker exec $CONTAINER_ID ipfs config --json Addresses.API

echo ""
echo "✅ Current Gateway configuration:"
docker exec $CONTAINER_ID ipfs config --json Addresses.Gateway

echo ""
echo "🔄 Restarting IPFS to apply IPv6 changes..."
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
echo "✅ IPFS should now be accessible via both IPv4 and IPv6!"
echo ""
echo "🌐 Access URLs:"

if [ "$IPV4_IP" != "Unable to detect" ]; then
    echo "  IPv4 Access:"
    echo "    - Web UI: http://$IPV4_IP:5001/webui"
    echo "    - API: http://$IPV4_IP:5001"
    echo "    - Gateway: http://$IPV4_IP:8080"
fi

if [ "$IPV6_IP" != "Unable to detect" ]; then
    echo "  IPv6 Access:"
    echo "    - Web UI: http://[$IPV6_IP]:5001/webui"
    echo "    - API: http://[$IPV6_IP]:5001"
    echo "    - Gateway: http://[$IPV6_IP]:8080"
fi

echo ""
echo "🔍 Test API access:"
if [ "$IPV4_IP" != "Unable to detect" ]; then
    echo "  IPv4: curl http://$IPV4_IP:5001/api/v0/id"
fi
if [ "$IPV6_IP" != "Unable to detect" ]; then
    echo "  IPv6: curl http://[$IPV6_IP]:5001/api/v0/id"
fi

echo ""
echo "📊 Check daemon status:"
docker exec $CONTAINER_ID ipfs id