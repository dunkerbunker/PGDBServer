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

# Load environment to grab whitelisted IPs
if [ -f "$(dirname "$0")/../.env" ]; then
    source "$(dirname "$0")/../.env"
fi

FE_SERVER=${FE_SERVER_IP:-169.58.6.224}
WHITELIST_IPS=("$FE_SERVER")

if [ ! -z "$USER_LOCAL_IP" ]; then
    WHITELIST_IPS+=("$USER_LOCAL_IP")
fi

if [ ! -z "$USER_LOCAL_IPS" ]; then
    for ip in $(echo "$USER_LOCAL_IPS" | tr ',' ' '); do
        WHITELIST_IPS+=("$ip")
    done
fi

echo "Applying DOCKER-USER iptables rules for whitelisted DB access..."

# Clear existing rules in case of re-runs
iptables -D DOCKER-USER -p tcp -m multiport --dports 5432,6379 -j DROP 2>/dev/null || true
for ip in "${WHITELIST_IPS[@]}"; do
    iptables -D DOCKER-USER -s "$ip" -p tcp -m multiport --dports 5432,6379 -j ACCEPT 2>/dev/null || true
done

# 1. ALLOW traffic from whitelisted IPs to Postgres and Redis
for ip in "${WHITELIST_IPS[@]}"; do
    echo "Whitelisting DB access from: $ip"
    iptables -I DOCKER-USER 1 -s "$ip" -p tcp -m multiport --dports 5432,6379 -j ACCEPT
done

# 2. DROP any other external traffic trying to hit Postgres and Redis
iptables -A DOCKER-USER -p tcp -m multiport --dports 5432,6379 -j DROP

echo "Database ports are now shielded from the public internet."

echo "Checking UFW Status:"
ufw status verbose
