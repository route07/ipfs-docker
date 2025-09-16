#!/bin/bash

# Script to check IPFS status and configuration
set -e

echo "🔍 IPFS Status Check"
echo "==================="

# Check if container is running
if ! sudo docker-compose ps | grep -q "Up"; then
    echo "❌ IPFS container is not running"
    echo "   Start it with: sudo docker-compose up -d"
    exit 1
fi

echo "✅ IPFS container is running"

# Get the container ID
CONTAINER_ID=$(sudo docker-compose ps -q ipfs)

echo ""
echo "📊 Current Configuration:"
echo "------------------------"

# Check API binding
echo "🔗 API Address:"
sudo docker exec $CONTAINER_ID ipfs config Addresses.API

# Check Gateway binding
echo "🌐 Gateway Address:"
sudo docker exec $CONTAINER_ID ipfs config Addresses.Gateway

# Check CORS configuration
echo ""
echo "🔓 CORS Configuration:"
echo "Access-Control-Allow-Origin:"
if sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin 2>/dev/null; then
    echo "✅ CORS Origin configured"
    sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin
else
    echo "❌ CORS Origin not configured"
fi

echo "Access-Control-Allow-Methods:"
if sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods 2>/dev/null; then
    echo "✅ CORS Methods configured"
    sudo docker exec $CONTAINER_ID ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods
else
    echo "❌ CORS Methods not configured"
fi

# Check if daemon is responding
echo ""
echo "🚀 Daemon Status:"
if sudo docker exec $CONTAINER_ID ipfs id > /dev/null 2>&1; then
    echo "✅ IPFS daemon is responding"
    echo ""
    echo "📋 Node Information:"
    sudo docker exec $CONTAINER_ID ipfs id
else
    echo "❌ IPFS daemon is not responding"
fi

# Test API endpoint
echo ""
echo "🧪 Testing API Endpoint:"
if curl -s http://localhost:5001/api/v0/id > /dev/null 2>&1; then
    echo "✅ API is accessible on localhost:5001"
else
    echo "❌ API is not accessible on localhost:5001"
fi

# Get external IPs
IPV4_IP=$(curl -4 -s ifconfig.me 2>/dev/null || curl -4 -s ipinfo.io/ip 2>/dev/null || echo "Unable to detect")
IPV6_IP=$(curl -6 -s ifconfig.me 2>/dev/null || curl -6 -s ipinfo.io/ip 2>/dev/null || echo "Unable to detect")

echo ""
echo "🌍 External IPs:"
echo "  IPv4: $IPV4_IP"
echo "  IPv6: $IPV6_IP"

if [ "$IPV4_IP" != "Unable to detect" ] || [ "$IPV6_IP" != "Unable to detect" ]; then
    echo ""
    echo "🔗 External Access URLs:"
    
    if [ "$IPV4_IP" != "Unable to detect" ]; then
        echo "  IPv4:"
        echo "    - Web UI: http://$IPV4_IP:5001/webui"
        echo "    - API: http://$IPV4_IP:5001"
        echo "    - Gateway: http://$IPV4_IP:8080"
    fi
    
    if [ "$IPV6_IP" != "Unable to detect" ]; then
        echo "  IPv6:"
        echo "    - Web UI: http://[$IPV6_IP]:5001/webui"
        echo "    - API: http://[$IPV6_IP]:5001"
        echo "    - Gateway: http://[$IPV6_IP]:8080"
    fi
fi