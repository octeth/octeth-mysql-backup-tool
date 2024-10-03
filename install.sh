#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Load configuration variables from .env file
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "Configuration file .env not found!"
    exit 1
fi

# Install Docker if not installed
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt update
    apt install -y docker.io
    systemctl enable docker
    systemctl start docker
else
    echo "Docker is already installed."
fi

# Build Custom Percona XtraBackup Docker Image with pigz
echo "Building custom Percona XtraBackup Docker image with pigz..."

# Create a temporary Dockerfile
cat <<EOF > Dockerfile_xtrabackup_pigz
# Dockerfile for percona-xtrabackup with pigz
FROM percona/percona-xtrabackup:2.4

RUN apt-get update && \
    apt-get install -y pigz && \
    rm -rf /var/lib/apt/lists/*
EOF

# Build the Docker image
docker build -t percona-xtrabackup-pigz:2.4 -f Dockerfile_xtrabackup_pigz .

# Remove the temporary Dockerfile
rm Dockerfile_xtrabackup_pigz

# Pull AWS CLI Docker image
echo "Pulling AWS CLI Docker image..."
docker pull amazon/aws-cli

echo "All necessary Docker images have been built and pulled successfully."
