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

# Update the package list
echo "Updating package list..."
apt update

# Install necessary packages
echo "Installing required packages..."
apt install -y curl unzip pigz python3-pip

# Install AWS CLI v2
if ! command -v aws &> /dev/null; then
    echo "Installing AWS CLI v2..."
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install
    rm -rf /tmp/aws /tmp/awscliv2.zip
else
    echo "AWS CLI v2 is already installed."
fi

# Install Docker if using Dockerized XtraBackup
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    apt install -y docker.io
    systemctl enable docker
    systemctl start docker
else
    echo "Docker is already installed."
fi

# Pull Percona XtraBackup Docker image
echo "Pulling Percona XtraBackup Docker image..."
docker pull percona/percona-xtrabackup:2.4

echo "All necessary packages and tools have been installed successfully."
