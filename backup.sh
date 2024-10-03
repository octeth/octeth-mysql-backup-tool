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

# Date variables
DATE=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="innodb_backup_$DATE.xbstream.gz"
DAYWEEK=$(date +%u)
DAYMONTH=$(date +%d)

# Ensure the backup directory exists
mkdir -p "$BACKUP_DIR"

# Start the backup process using Docker
echo "Starting the backup process..."
docker run --rm \
    -v "$DATA_DIR":/var/lib/mysql:ro \
    -v "$BACKUP_DIR":/backup \
    percona/percona-xtrabackup:2.4 \
    bash -c "xtrabackup --backup --stream=xbstream --parallel=4 --datadir=/var/lib/mysql | gzip > /backup/$FILENAME"

# Check backup success
if [ $? -eq 0 ]; then
    echo "Backup was successful."

    # Check if AWS credentials are provided
    if [[ -n "$AWS_ACCESS_KEY_ID" && -n "$AWS_SECRET_ACCESS_KEY" && -n "$AWS_DEFAULT_REGION" ]]; then
        echo "AWS credentials detected. Proceeding with upload..."

        # Determine the S3 path based on the date
        if [[ "$DAYMONTH" == "01" || "$DAYMONTH" == "11" || "$DAYMONTH" == "21" || "$DAYMONTH" == "31" ]]; then
            S3_PATH="$S3_BUCKET/$LONGTERM/$FILENAME"
        else
            S3_PATH="$S3_BUCKET/$SHORTTERM/$DAYWEEK/$FILENAME"
        fi

        # Upload to AWS S3 using Docker
        echo "Uploading backup to S3..."
        docker run --rm \
            -v "$BACKUP_DIR":/backup \
            -e AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID" \
            -e AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY" \
            -e AWS_DEFAULT_REGION="$AWS_DEFAULT_REGION" \
            amazon/aws-cli \
            s3 cp "/backup/$FILENAME" "$S3_PATH"

        echo "Backup uploaded to $S3_PATH"

        # Cleanup local backup file
        rm -f "$BACKUP_DIR/$FILENAME"
        echo "Local backup file cleaned up."
    else
        echo "AWS credentials not set. Skipping S3 upload."
        echo "Backup file is located at: $BACKUP_DIR/$FILENAME"
    fi
else
    echo "Backup failed."
    exit 1
fi
