#!/bin/bash
set -e

# Startup script for TPU VM - disk mounting and task setup
echo "Starting TPU VM initialization..."

# Create mount points
sudo mkdir -p /mnt/data
# sudo mkdir -p /mnt/checkpoints

# Mount data disk (read-only)
echo "Mounting data disk..."
DATA_DISK=nvme0n2
sudo mount -t ext4 -o ro,noload /dev/$DATA_DISK /mnt/data \
  || echo "WARN: mount failed; continuing"

# Install/update dependencies
echo "Installing dependencies..."
# sudo apt-get update
curl -LsSf https://astral.sh/uv/install.sh | sh
# Create training directory structure
sudo mkdir -p /opt/training
sudo chown $(whoami):$(whoami) /opt/training
cd /opt/training
# sudo apt install -y git
git clone https://github.com/cjim8889/md4.git
cd /opt/training/md4
git checkout efficient-arch

echo "TPU VM initialization completed successfully"
