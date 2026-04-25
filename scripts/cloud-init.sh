#!/bin/bash
# DigitalOcean Droplet Startup Script (Cloud-Init / User Data)
# Paste this entire script into the "User Data" field at the bottom 
# of the DigitalOcean droplet creation screen.

set -e

echo "Starting User Data provisioning..." > /var/log/cloud-init-custom.log

# 1. Update system and install base dependencies
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y curl wget git unzip ufw cron

# 2. Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 3. Configure UFW (Firewall)
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https
ufw --force enable

# 4. Create the deployment folder
mkdir -p /root/DBServer
chmod 700 /root/DBServer

echo "Basic infrastructure provisioned. Ready for git clone." >> /var/log/cloud-init-custom.log
