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

# Pull Percona XtraBackup Docker image
echo "Pulling Percona XtraBackup Docker image..."
docker pull percona/percona-xtrabackup:2.4

# Pull AWS CLI Docker image
echo "Pulling AWS CLI Docker image..."
docker pull amazon/aws-cli

echo "All necessary Docker images have been pulled successfully."
