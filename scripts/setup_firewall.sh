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
# Docker manipulates iptables directly and bypasses UFW by default!
# If a port is published via docker-compose (e.g. 5432:5432), it IS PUBLIC.
#
# Our docker-compose.yml prevents this by specifically binding to the VPC_IP:
# ports:
#   - "${VPC_IP}:5432:5432"
#
# As long as VPC_IP is a private 10.x.x.x network IP, it is physically impossible
# to reach from the public Internet, rendering complex UFW-Docker workarounds unnecessary!

echo "Checking UFW Status:"
ufw status verbose
