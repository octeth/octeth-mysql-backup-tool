#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Load configuration variables from .env file (if needed)
ENV_FILE="$(dirname "$0")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
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

# Build Custom Docker Image with Percona XtraBackup 2.4 and pigz
echo "Building custom Docker image with Percona XtraBackup 2.4 and pigz..."

# Create a temporary Dockerfile
cat <<EOF > Dockerfile_xtrabackup_pigz
# Use Ubuntu 20.04 as base image
FROM ubuntu:20.04

# Set environment variables to prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install necessary packages and Percona XtraBackup
RUN apt-get update && \
    apt-get install -y mysql-client curl wget lsb-release gnupg2 && \
    wget https://repo.percona.com/apt/percona-release_latest.generic_all.deb && \
    dpkg -i percona-release_latest.generic_all.deb && \
    percona-release setup ps57 && \
    apt-get update && \
    apt-get install -y percona-xtrabackup-24 pigz && \
    rm -rf /var/lib/apt/lists/*

CMD ["/bin/bash"]
EOF

# Build the Docker image
docker build -t percona-xtrabackup-pigz:2.4 -f Dockerfile_xtrabackup_pigz .

# Remove the temporary Dockerfile
rm Dockerfile_xtrabackup_pigz

# Pull AWS CLI Docker image
echo "Pulling AWS CLI Docker image..."
docker pull amazon/aws-cli

echo "All necessary Docker images have been built and pulled successfully."
