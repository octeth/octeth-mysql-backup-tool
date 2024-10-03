#!/bin/bash

set -euo pipefail  # Exit immediately if a command exits with a non-zero status, including in pipelines

# Load configuration variables from .env file
ENV_FILE="$(dirname "$0")/.env"
if [[ -f "$ENV_FILE" ]]; then
    source "$ENV_FILE"
else
    echo "Configuration file .env not found!"
    exit 1
fi

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Specify the exact backup file name to restore (pass as an argument)
if [[ -z "${1-}" ]]; then
    echo "Usage: $0 <backup_filename>"
    exit 1
fi
FILENAME="$1"

# Download the backup from S3 using Docker, if AWS credentials are provided
if [[ -n "${AWS_ACCESS_KEY_ID-}" && -n "${AWS_SECRET_ACCESS_KEY-}" && -n "${AWS_DEFAULT_REGION-}" ]]; then
    echo "AWS credentials detected. Downloading the backup from S3..."
    docker run --rm \
        -v "$BACKUP_DIR":/backup \
        -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
        -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
        -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
        amazon/aws-cli \
        s3 cp "$S3_BUCKET/$FILENAME" "/backup/$FILENAME"
else
    echo "AWS credentials not set. Skipping S3 download."
    if [[ ! -f "$BACKUP_DIR/$FILENAME" ]]; then
        echo "Backup file not found in $BACKUP_DIR. Please place the backup file in the directory or provide AWS credentials."
        exit 1
    else
        echo "Using existing backup file in $BACKUP_DIR."
    fi
fi

# Decompress and extract the backup using Docker
echo "Decompressing and extracting the backup..."
docker run --rm \
    -v "$BACKUP_DIR":/backup \
    percona/percona-xtrabackup:2.4 \
    bash -c "cd /backup && gzip -d $FILENAME && xbstream -x < ${FILENAME%.gz}"

# Stop MySQL service
echo "Stopping MySQL service..."
if [[ -n "${MYSQL_CONTAINER_NAME-}" ]]; then
    docker stop "$MYSQL_CONTAINER_NAME"
else
    systemctl stop mysql
fi

# Clean existing data directory
echo "Cleaning existing MySQL data directory..."
rm -rf "$MYSQL_DATA_DIR"/*

# Restore the backup using Docker
echo "Restoring the backup..."
docker run --rm \
    -v "$BACKUP_DIR":/backup \
    -v "$MYSQL_DATA_DIR":/var/lib/mysql \
    percona/percona-xtrabackup:2.4 \
    bash -c "xtrabackup --prepare --target-dir=/backup && xtrabackup --copy-back --target-dir=/backup"

# Adjust ownership
echo "Adjusting file ownership..."
chown -R "$MYSQL_USER":"$MYSQL_GROUP" "$MYSQL_DATA_DIR"

# Start MySQL service
echo "Starting MySQL service..."
if [[ -n "${MYSQL_CONTAINER_NAME-}" ]]; then
    docker start "$MYSQL_CONTAINER_NAME"
else
    systemctl start mysql
fi

# Cleanup
rm -rf "$BACKUP_DIR"/*
echo "Database restoration completed successfully."
