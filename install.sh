#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Update the package list
echo "Updating package list..."
apt update

# Install necessary packages
echo "Installing required packages..."
apt install -y curl unzip pigz python3-pip

# Install AWS CLI v2
echo "Installing AWS CLI v2..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install
rm -rf /tmp/aws /tmp/awscliv2.zip

# Install Percona XtraBackup 2.4 in Docker (Ubuntu 20.04)
echo "Setting up Percona XtraBackup 2.4 Docker container..."
docker pull percona/percona-xtrabackup:2.4

echo "All necessary packages and tools have been installed successfully."
