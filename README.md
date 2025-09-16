# IPFS Private Cluster Node Setup

This setup provides a Docker-based IPFS node configured as the initial node in a private cluster with proper CORS configuration for web access.

## Features

- 🐳 **Docker-based**: Easy deployment and management
- 🔒 **Private Cluster**: No connection to public IPFS network
- 🌐 **CORS Enabled**: Web applications can access the API and Gateway
- 📦 **Persistent Storage**: Data persists across container restarts
- 🚀 **One-click Setup**: Automated initialization script

## Quick Start

1. **Clone or download this setup**
2. **Run the initialization script**:
   ```bash
   ./init-ipfs.sh
   ```

That's it! Your IPFS node will be running and configured.

## Manual Setup

If you prefer to set up manually:

1. **Start the IPFS container**:
   ```bash
   docker-compose up -d
   ```

2. **Initialize IPFS**:
   ```bash
   docker exec $(docker-compose ps -q ipfs) ipfs init --profile=server
   ```

3. **Configure for private cluster**:
   ```bash
   # Remove default bootstrap nodes
   docker exec $(docker-compose ps -q ipfs) ipfs bootstrap rm --all
   
   # Configure API and Gateway
   docker exec $(docker-compose ps -q ipfs) ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
   docker exec $(docker-compose ps -q ipfs) ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
   
   # Disable MDNS discovery
   docker exec $(docker-compose ps -q ipfs) ipfs config Discovery.MDNS.Enabled false
   ```

4. **Configure CORS** (already done in the config file):
   ```bash
   # API CORS
   docker exec $(docker-compose ps -q ipfs) ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
   docker exec $(docker-compose ps -q ipfs) ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT", "DELETE", "OPTIONS"]'
   
   # Gateway CORS
   docker exec $(docker-compose ps -q ipfs) ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Origin '["*"]'
   docker exec $(docker-compose ps -q ipfs) ipfs config --json Gateway.HTTPHeaders.Access-Control-Allow-Methods '["GET", "POST", "PUT", "DELETE", "OPTIONS"]'
   ```

5. **Restart to apply configuration**:
   ```bash
   docker-compose restart
   ```

## Access Points

Once running, your IPFS node will be accessible at:

- **API**: `http://localhost:5001` (or `http://0.0.0.0:5001` from external machines)
- **Web UI**: `http://localhost:5001/webui` (or `http://0.0.0.0:5001/webui` from external machines)
- **Gateway**: `http://localhost:8080` (or `http://0.0.0.0:8080` from external machines)
- **Swarm**: `4001` (for peer-to-peer connections)

## Testing the Setup

### Test API Access
```bash
curl http://localhost:5001/api/v0/id
```

### Test Gateway Access
```bash
# Add a file
echo "Hello IPFS!" > test.txt
curl -X POST -F file=@test.txt http://localhost:5001/api/v0/add

# Access via gateway (replace HASH with the returned hash)
curl http://localhost:8080/ipfs/HASH
```

### Test CORS from Browser
```javascript
// This should work from any web page
fetch('http://localhost:5001/api/v0/id')
  .then(response => response.json())
  .then(data => console.log(data));
```

## Adding More Nodes to the Cluster

To add additional nodes to your private cluster:

1. **Get the bootstrap address** of this node:
   ```bash
   docker exec $(docker-compose ps -q ipfs) ipfs id -f="<addrs>"
   ```

2. **On the new node**, add this node as a bootstrap peer:
   ```bash
   ipfs bootstrap add /ip4/YOUR_SERVER_IP/tcp/4001/ipfs/NODE_ID
   ```

3. **Remove default bootstrap nodes** on the new node:
   ```bash
   ipfs bootstrap rm --all
   ```

## Configuration Files

- `docker-compose.yml`: Docker Compose configuration
- `ipfs-config/config`: IPFS configuration with CORS settings
- `init-ipfs.sh`: Automated initialization script

## Data Persistence

- IPFS data is stored in `./ipfs-data/`
- Configuration is stored in `./ipfs-config/`
- Both directories persist across container restarts

## Security Considerations

⚠️ **Important Security Notes**:

1. **CORS is set to allow all origins (`*`)** - This is convenient for development but should be restricted in production:
   ```bash
   # Restrict to specific domains
   docker exec $(docker-compose ps -q ipfs) ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin '["https://yourdomain.com", "https://app.yourdomain.com"]'
   ```

2. **API is accessible from any IP** - Consider restricting access:
   ```bash
   # Restrict API to localhost only
   docker exec $(docker-compose ps -q ipfs) ipfs config Addresses.API /ip4/127.0.0.1/tcp/5001
   ```

3. **No authentication** - The API has no built-in authentication. Consider using a reverse proxy with authentication for production use.

## Troubleshooting

### Container won't start
```bash
docker-compose logs
```

### IPFS not responding
```bash
docker-compose ps
docker exec $(docker-compose ps -q ipfs) ipfs daemon --debug
```

### Web UI only accessible from localhost
If the Web UI shows `http://127.0.0.1:5001/webui` instead of being accessible from all interfaces:

```bash
# Run the comprehensive fix script
./fix-ipfs-access.sh

# Or run the specific Web UI fix
./fix-webui-binding.sh

# Or manually fix:
docker exec $(docker-compose ps -q ipfs) ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
docker-compose restart
```

### "Could not connect to the Kubo RPC" error
If you see this error in the Web UI:

```bash
# Run the comprehensive fix script
./fix-ipfs-access.sh

# Check current status
./check-ipfs-status.sh
```

This usually means:
1. API is bound to `127.0.0.1` instead of `0.0.0.0`
2. CORS is not properly configured for external access
3. The daemon needs to be restarted after configuration changes

### IPv6/IPv4 binding issues
If your server has an IPv6 address but IPFS is only binding to IPv4:

```bash
# Fix IPv6 binding
./fix-ipv6-binding.sh

# Check status with both IPv4 and IPv6
./check-ipfs-status.sh
```

This will configure IPFS to bind to both IPv4 (`0.0.0.0`) and IPv6 (`::`) interfaces.

### Reset everything
```bash
docker-compose down
rm -rf ipfs-data ipfs-config
./init-ipfs.sh
```

## Useful Commands

```bash
# View logs
docker-compose logs -f

# Stop the node
docker-compose down

# Restart the node
docker-compose restart

# Access IPFS CLI
docker exec -it $(docker-compose ps -q ipfs) ipfs

# Check node status
docker exec $(docker-compose ps -q ipfs) ipfs id

# View configuration
docker exec $(docker-compose ps -q ipfs) ipfs config show

# Check IPFS status and configuration
./check-ipfs-status.sh

# Fix API access and CORS issues
./fix-ipfs-access.sh

# Fix IPv6 binding issues
./fix-ipv6-binding.sh

# Setup CORS only
./setup-cors.sh
```

## Next Steps

1. **Add more nodes** to create a distributed cluster
2. **Set up monitoring** for your IPFS nodes
3. **Configure backup strategies** for your data
4. **Implement authentication** for production use
5. **Set up load balancing** if needed

## Support

For issues with this setup, check:
- [IPFS Documentation](https://docs.ipfs.io/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- Container logs: `docker-compose logs`