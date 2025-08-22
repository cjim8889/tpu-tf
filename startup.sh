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
if [ ! -z "$DATA_DISK" ]; then
    sudo mount -o ro /dev/$DATA_DISK /mnt/data
    echo "Data disk mounted at /mnt/data"
else
    echo "Warning: No data disk found"
fi

# Get checkpoint bucket from metadata
# echo "Setting up Cloud Storage bucket access..."
# CHECKPOINT_BUCKET=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/attributes/checkpoint-bucket" -H "Metadata-Flavor: Google")
# echo "Checkpoint bucket: $CHECKPOINT_BUCKET"

# Install gcsfuse for mounting Cloud Storage bucket
# echo "Installing gcsfuse..."
# export GCSFUSE_REPO=gcsfuse-`lsb_release -c -s`
# echo "deb https://packages.cloud.google.com/apt $GCSFUSE_REPO main" | sudo tee /etc/apt/sources.list.d/gcsfuse.list
# curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
# sudo apt-get update
# sudo apt-get install -y gcsfuse

# # Mount checkpoint bucket using gcsfuse
# echo "Mounting checkpoint bucket..."
# if [ ! -z "$CHECKPOINT_BUCKET" ]; then
#     gcsfuse --implicit-dirs "$CHECKPOINT_BUCKET" /mnt/checkpoints
#     echo "Checkpoint bucket $CHECKPOINT_BUCKET mounted at /mnt/checkpoints"
# else
#     echo "Warning: No checkpoint bucket specified in metadata"
# fi

# Install/update dependencies
echo "Installing dependencies..."
sudo apt-get update
curl -LsSf https://astral.sh/uv/install.sh | sh

# Create training directory structure
sudo mkdir -p /opt/training
sudo chown $(whoami):$(whoami) /opt/training

cd /opt/training
sudo apt install -y git
git clone https://github.com/cjim8889/md4.git

cd /opt/training/md4

echo "TPU VM initialization completed successfully"
