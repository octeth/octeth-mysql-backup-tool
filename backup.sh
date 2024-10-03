#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status

# Configuration variables
S3_BUCKET="s3://your-s3-bucket-name"
DATA_DIR="/var/lib/mysql"  # Adjust if different
BACKUP_DIR="/root/mysql_backups"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
FILENAME="innodb_backup_$DATE.xbstream.gz"
LONGTERM="longterm"
SHORTTERM="shortterm"
DAYWEEK=$(date +%u)
DAYMONTH=$(date +%d)

# Ensure the backup directory exists
mkdir -p $BACKUP_DIR

# Start the backup process using Docker
echo "Starting the backup process..."
docker run --rm \
  --name xtrabackup \
  -v $DATA_DIR:/var/lib/mysql \
  -v $BACKUP_DIR:/backup \
  percona/percona-xtrabackup:2.4 \
  bash -c "xtrabackup --backup --stream=xbstream --parallel=4 --datadir=/var/lib/mysql 2> /tmp/backup.log" | pigz > $BACKUP_DIR/$FILENAME

# Check backup success
if [ $? -eq 0 ]; then
    echo "Backup was successful, proceeding with upload..."
    # Determine if the backup is for long-term or short-term storage
    if [[ "$DAYMONTH" == "01" || "$DAYMONTH" == "11" || "$DAYMONTH" == "21" || "$DAYMONTH" == "31" ]]; then
        aws s3 cp $BACKUP_DIR/$FILENAME $S3_BUCKET/$LONGTERM/$FILENAME
        echo "Backup uploaded to long-term storage: $S3_BUCKET/$LONGTERM/$FILENAME"
    else
        aws s3 cp $BACKUP_DIR/$FILENAME $S3_BUCKET/$SHORTTERM/$DAYWEEK/$FILENAME
        echo "Backup uploaded to short-term storage: $S3_BUCKET/$SHORTTERM/$DAYWEEK/$FILENAME"
    fi
else
    echo "Backup failed, please check the Docker container logs for details."
    exit 1
fi

# Cleanup local files
rm -f $BACKUP_DIR/$FILENAME
echo "Local backup files cleaned up."
