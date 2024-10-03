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

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Specify the exact backup file name to restore
FILENAME="innodb_backup_specific-date.xbstream.gz"  # Update this with the actual file name

# Download the backup from S3
echo "Downloading the backup from S3..."
aws s3 cp "$S3_BUCKET/path-to-your-backup/$FILENAME" "$BACKUP_DIR/$FILENAME"

# Decompress and extract the backup
echo "Decompressing and extracting the backup..."
pigz -dc "$BACKUP_DIR/$FILENAME" | xbstream -x -C "$BACKUP_DIR"

# Stop MySQL service
echo "Stopping MySQL service..."
docker stop mysql_container  # Replace with your MySQL Docker container name

# Clean existing data directory
echo "Cleaning existing MySQL data directory..."
rm -rf "$MYSQL_DATA_DIR/*"

# Restore the backup using Docker
echo "Restoring the backup..."
docker run --rm \
    -v "$BACKUP_DIR":/backup \
    -v "$MYSQL_DATA_DIR":/var/lib/mysql \
    percona/percona-xtrabackup:2.4 \
    bash -c "xtrabackup --prepare --target-dir=/backup && xtrabackup --copy-back --target-dir=/backup"

# Adjust ownership
echo "Adjusting file ownership..."
chown -R mysql:mysql "$MYSQL_DATA_DIR"

# Start MySQL service
echo "Starting MySQL service..."
docker start mysql_container  # Replace with your MySQL Docker container name

# Cleanup
rm -rf "$BACKUP_DIR/*"
echo "Database restoration completed successfully."
