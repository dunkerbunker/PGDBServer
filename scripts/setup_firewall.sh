#!/bin/bash
# Basic UFW setup for the Database server
# Run this as root

set -e

echo "Setting up UFW Firewall Rules..."

# Default policies
ufw default deny incoming
ufw default allow outgoing

# Always allow SSH or you will get locked out!
# Consider restricting this to your specific IP: 
# ufw allow from YOUR_IP to any port 22
ufw allow ssh

# Allow HTTP and HTTPS for Caddy (Grafana Reverse Proxy)
ufw allow http
ufw allow https

# Enable UFW
ufw --force enable

echo "UFW is active and protecting public interfaces."

# IMPORTANT DOCKER NETWORKING NOTE:
# Since you are using a Public IP, Docker will expose 5432 and 6379 to the entire world, bypassing UFW!
# We absolutely must use the iptables DOCKER-USER chain to enforce that ONLY your FE Server can connect.

# Load environment to grab FE_SERVER_IP
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

FE_SERVER=${FE_SERVER_IP:-159.65.138.144}

echo "Applying DOCKER-USER iptables rules to restrict DB access strictly to $FE_SERVER..."

# Clear existing rules in case of re-runs
iptables -D DOCKER-USER -p tcp -m multiport --dports 5432,6379 -j DROP 2>/dev/null || true
iptables -D DOCKER-USER -s $FE_SERVER -p tcp -m multiport --dports 5432,6379 -j ACCEPT 2>/dev/null || true

# 1. ALLOW traffic from your FE Server to Postgres and Redis
iptables -I DOCKER-USER 1 -s $FE_SERVER -p tcp -m multiport --dports 5432,6379 -j ACCEPT

# 2. DROP any other external traffic trying to hit Postgres and Redis
iptables -I DOCKER-USER 2 -p tcp -m multiport --dports 5432,6379 -j DROP

echo "Database ports are now shielded from the public internet."

echo "Checking UFW Status:"
ufw status verbose
