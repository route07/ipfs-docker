# IPFS Private Cluster Setup Guide

This guide explains how to join additional nodes to your IPFS private cluster.

## 🌐 **Current Cluster Node Information**

**Node ID**: `12D3KooWPPN829Tton19NgLwrTvKfzKrYTXPv7ctvqPDfBhE87vB`

**Bootstrap Addresses**:
- **IPv4**: `/ip4/46.62.197.187/tcp/4001/ipfs/12D3KooWPPN829Tton19NgLwrTvKfzKrYTXPv7ctvqPDfBhE87vB`
- **IPv6**: `/ip6/2a01:4f9:c013:9177::1/tcp/4001/ipfs/12D3KooWPPN829Tton19NgLwrTvKfzKrYTXPv7ctvqPDfBhE87vB`

## 🚀 **Adding a New Node to the Cluster**

### **Step 1: Setup New Node**

On the new server, clone this repository and set up IPFS:

```bash
# Clone the repository
git clone <your-repository-url>
cd ipfs

# Run initial setup
./init-ipfs.sh
```

### **Step 2: Configure as Private Cluster Member**

```bash
# Configure as private cluster
./configure-private-cluster.sh
```

### **Step 3: Add Bootstrap Peer**

Add the existing cluster node as a bootstrap peer:

```bash
# Add IPv4 bootstrap peer
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap add /ip4/46.62.197.187/tcp/4001/ipfs/12D3KooWPPN829Tton19NgLwrTvKfzKrYTXPv7ctvqPDfBhE87vB

# Add IPv6 bootstrap peer (optional, for redundancy)
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap add /ip6/2a01:4f9:c013:9177::1/tcp/4001/ipfs/12D3KooWPPN829Tton19NgLwrTvKfzKrYTXPv7ctvqPDfBhE87vB
```

### **Step 4: Restart IPFS**

```bash
# Restart to apply bootstrap configuration
sudo docker-compose restart
```

### **Step 5: Verify Connection**

```bash
# Check if nodes are connected
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs swarm peers

# Check bootstrap nodes
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap list
```

## 🔄 **Adding This Node to Existing Cluster**

If you want to add this node to an existing cluster, run this command on the existing cluster nodes:

```bash
# Get this node's information
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs id -f="<addrs>"

# Add this node as bootstrap peer on existing nodes
ipfs bootstrap add /ip4/YOUR_NEW_NODE_IP/tcp/4001/ipfs/YOUR_NODE_ID
```

## 📋 **Automated Setup Script**

For convenience, you can use the automated setup script:

```bash
# Run the cluster join script
./join-cluster.sh
```

## 🔍 **Verification Commands**

### **Check Cluster Status**
```bash
# View all connected peers
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs swarm peers

# View bootstrap nodes
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap list

# Check node information
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs id
```

### **Test Data Sharing**
```bash
# On Node 1: Add a file
echo "Hello from Node 1!" > test.txt
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs add test.txt

# On Node 2: Retrieve the file using the hash
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs cat /ipfs/HASH_FROM_NODE_1
```

## 🌐 **Network Requirements**

### **Firewall Configuration**
Ensure these ports are open:
- **4001**: IPFS swarm port (TCP/UDP)
- **5001**: IPFS API port (TCP)
- **8080**: IPFS Gateway port (TCP)

### **Docker Network**
The Docker Compose configuration automatically handles networking, but ensure:
- Containers can communicate with each other
- External access to API/Gateway ports is available

## 🔧 **Troubleshooting**

### **Nodes Not Connecting**
1. **Check firewall**: Ensure port 4001 is open
2. **Check bootstrap**: Verify bootstrap nodes are added correctly
3. **Check network**: Test connectivity between nodes
4. **Check logs**: `sudo docker-compose logs`

### **Connection Issues**
```bash
# Test connectivity
telnet <node-ip> 4001

# Check IPFS daemon status
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs daemon --debug
```

### **Reset Bootstrap Configuration**
```bash
# Remove all bootstrap nodes
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap rm --all

# Re-add cluster nodes
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap add /ip4/46.62.197.187/tcp/4001/ipfs/12D3KooWPPN829Tton19NgLwrTvKfzKrYTXPv7ctvqPDfBhE87vB
```

## 📊 **Cluster Management**

### **Adding Multiple Nodes**
For a cluster with multiple nodes, add all existing nodes as bootstrap peers:

```bash
# Add all cluster nodes as bootstrap peers
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap add /ip4/NODE1_IP/tcp/4001/ipfs/NODE1_ID
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap add /ip4/NODE2_IP/tcp/4001/ipfs/NODE2_ID
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs bootstrap add /ip4/NODE3_IP/tcp/4001/ipfs/NODE3_ID
```

### **Monitoring Cluster Health**
```bash
# Check peer count
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs swarm peers | wc -l

# Check node status
sudo docker exec $(sudo docker-compose ps -q ipfs) ipfs stats bw
```

## 🎯 **Best Practices**

1. **Redundancy**: Add multiple bootstrap nodes for fault tolerance
2. **Monitoring**: Regularly check cluster connectivity
3. **Backup**: Keep configuration files in version control
4. **Security**: Use firewall rules to restrict access
5. **Documentation**: Maintain a list of all cluster nodes

## 📞 **Support**

For issues with cluster setup:
1. Check the troubleshooting section above
2. Review IPFS logs: `sudo docker-compose logs`
3. Verify network connectivity between nodes
4. Ensure all nodes have the same private cluster configuration