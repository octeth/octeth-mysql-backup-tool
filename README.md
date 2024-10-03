# MySQL Backup and Restore Scripts using Percona XtraBackup and AWS S3

This repository contains a set of Bash scripts designed to perform backups and restores of a MySQL 5.7 database using Percona XtraBackup. The backups are compressed, stored locally, and uploaded to AWS S3 for long-term and short-term storage. The scripts are compatible with Ubuntu 22.04 or newer versions and leverage Docker to run Percona XtraBackup 2.4.

This tool is built specifically for [Octeth Email Marketing Software](https://octeth.com/).

---

## Table of Contents

- [Prerequisites](#prerequisites)
- [Setup and Installation](#setup-and-installation)
    - [Clone the Repository](#clone-the-repository)
    - [Configure Environment Variables](#configure-environment-variables)
    - [Run the Installation Script](#run-the-installation-script)
- [Usage](#usage)
    - [Performing a Backup](#performing-a-backup)
    - [Restoring from a Backup](#restoring-from-a-backup)
- [Scripts Overview](#scripts-overview)
    - [install.sh](#installsh)
    - [backup.sh](#backupsh)
    - [restore.sh](#restoresh)
- [Configuration](#configuration)
    - [.env File](#env-file)
- [AWS CLI Configuration](#aws-cli-configuration)
- [Docker Configuration](#docker-configuration)
- [Troubleshooting](#troubleshooting)
- [Security Considerations](#security-considerations)
- [License](#license)

---

## Prerequisites

Before using these scripts, ensure that you have the following installed and configured on your Ubuntu 22.04 system:

- **Docker**: To run Percona XtraBackup 2.4 in a container.
- **AWS CLI v2**: For uploading backups to AWS S3.
- **MySQL 5.7**: The database you intend to back up.
- **Pigz**: For parallel compression of backup files.

---

## Setup and Installation

### Clone the Repository

```bash
git clone git@github.com:cemhurturk/innodb-backup-tool.git
cd innodb-backup-tool
```

### Configure Environment Variables

Create a `.env` file in the root directory of the repository to store configuration variables.

```bash
touch .env
```

Edit the `.env` file and add your configuration variables. See the [Configuration](#configuration) section for details.

### Run the Installation Script

The `install.sh` script installs all necessary tools and pulls the required Docker image.

```bash
sudo chmod +x install.sh
sudo ./install.sh
```

---

## Usage

### Performing a Backup

Run the `backup.sh` script to perform a backup of your MySQL database.

```bash
sudo chmod +x backup.sh
sudo ./backup.sh
```

The script will:

- Create a compressed backup of your MySQL data directory.
- Upload the backup to AWS S3, organizing it into long-term or short-term storage based on the date.
- Clean up the local backup file after upload.

### Restoring from a Backup

To restore your database from a backup, run the `restore.sh` script.

1. Edit the `restore.sh` script or update your `.env` file to specify the exact backup file name (`FILENAME`) you wish to restore.

2. Run the script:

   ```bash
   sudo chmod +x restore.sh
   sudo ./restore.sh
   ```

The script will:

- Download the specified backup from AWS S3.
- Decompress and extract the backup files.
- Stop the MySQL service.
- Clean the existing MySQL data directory.
- Restore the backup to the data directory.
- Adjust file ownership.
- Start the MySQL service.
- Clean up the local backup files.

---

## Scripts Overview

### install.sh

This script installs the required packages and tools:

- Updates the package list.
- Installs `curl`, `unzip`, `pigz`, and `python3-pip`.
- Installs AWS CLI v2.
- Installs Docker.
- Pulls the Percona XtraBackup 2.4 Docker image.

### backup.sh

This script performs the backup process:

- Loads configuration variables from the `.env` file.
- Generates date-based variables for file naming.
- Creates the backup directory if it doesn't exist.
- Runs the backup process using Percona XtraBackup inside a Docker container.
- Compresses the backup using `pigz`.
- Uploads the backup to AWS S3, organizing it into long-term or short-term storage.
- Cleans up the local backup file.

### restore.sh

This script restores the database from a backup:

- Loads configuration variables from the `.env` file.
- Downloads the specified backup file from AWS S3.
- Decompresses and extracts the backup files.
- Stops the MySQL service.
- Cleans the existing MySQL data directory.
- Restores the backup using Percona XtraBackup inside a Docker container.
- Adjusts file ownership of the data directory.
- Starts the MySQL service.
- Cleans up the local backup files.

---

## Configuration

### .env File

All configuration variables are stored in the `.env` file located in the root directory of the repository. Below is an example of what the `.env` file should contain:

The latest version of the `.env` file can be found in the repository as `.env.example` file.

```bash
# .env file

# S3 Bucket Configuration
S3_BUCKET="s3://your-s3-bucket-name"

# Backup Directories
DATA_DIR="/var/lib/mysql"          # Path to your MySQL data directory
BACKUP_DIR="/root/mysql_backups"   # Local directory to store backups

# MySQL Data Directory (for restore.sh)
MYSQL_DATA_DIR="/var/lib/mysql"    # Path to your MySQL data directory

# AWS Credentials (if not set globally)
# AWS_ACCESS_KEY_ID="your-access-key-id"
# AWS_SECRET_ACCESS_KEY="your-secret-access-key"
# AWS_DEFAULT_REGION="your-region"

# Backup Storage Configuration
LONGTERM="longterm"    # S3 folder for long-term backups
SHORTTERM="shortterm"  # S3 folder for short-term backups

# Docker Configuration
MYSQL_CONTAINER_NAME="mysql_container"  # Name of your MySQL Docker container
```

**Notes:**

- Replace the placeholder values with your actual configuration.
- If your MySQL data directory or Docker container name differs, update the `DATA_DIR`, `MYSQL_DATA_DIR`, and `MYSQL_CONTAINER_NAME` variables accordingly.
- Be cautious with sensitive information. Avoid storing AWS credentials in the `.env` file if possible.

---

## AWS CLI Configuration

Ensure that AWS CLI is configured with the necessary credentials and region settings.

```bash
aws configure
```

Alternatively, you can export AWS credentials as environment variables or use IAM roles if running on AWS EC2 instances.

---

## Docker Configuration

The scripts use Docker to run Percona XtraBackup 2.4, which is compatible with MySQL 5.7.

- Ensure Docker is installed and running on your system.
- Update the `MYSQL_CONTAINER_NAME` variable in the `.env` file with the name of your MySQL Docker container.
- The scripts assume that your MySQL data directory is accessible and correctly mapped for Docker volume mounting.

---

## Troubleshooting

- **Backup Fails Immediately:**
    - Check the Docker logs for the `xtrabackup` container.
    - Ensure the `DATA_DIR` path is correct and accessible.
- **AWS S3 Upload Fails:**
    - Verify AWS CLI is configured with correct credentials.
    - Ensure the S3 bucket name and path are correct.
- **Restore Process Issues:**
    - Confirm that the `FILENAME` in `restore.sh` or `.env` matches the backup file you intend to restore.
    - Make sure the MySQL service is properly stopped before restoring.
- **Permission Errors:**
    - Ensure you run the scripts with sufficient privileges (`sudo` may be required).
    - Verify that the `chown` command in `restore.sh` points to the correct user and group (`mysql:mysql`).

---

## Security Considerations

- **Sensitive Data:** Avoid committing the `.env` file to version control if it contains sensitive information.
    - Add `.env` to your `.gitignore` file.
- **File Permissions:** Set appropriate permissions on the `.env` file and backup directories to prevent unauthorized access.

  ```bash
  chmod 600 .env
  chmod -R 700 /root/mysql_backups
  ```

- **AWS Credentials:** Use IAM roles or AWS CLI configuration rather than storing credentials in the `.env` file.
- **Data Encryption:** Consider encrypting your backups before uploading them to S3 for an additional layer of security.

---

## Contributions and Feedback

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/cemhurturk/innodb-backup-tool/issues) or submit a pull request.

---

## Acknowledgments

- **Percona XtraBackup:** An open-source hot backup utility for MySQL-based servers.
- **AWS S3:** Scalable storage in the cloud provided by Amazon Web Services.
- **Docker:** A platform for developing, shipping, and running applications in containers.

---

**Disclaimer:** These scripts are provided as-is without any warranty. Use them at your own risk, and always ensure you have proper backups before performing restore operations.

---

*For any questions or support, please contact [cem.hurturk@gmail.com](mailto:cem.hurturk@gmail.com).*