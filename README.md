# MySQL Backup and Restore Scripts using Percona XtraBackup and AWS S3

This repository contains a set of Bash scripts designed to perform backups and restores of a MySQL 5.7 database using Percona XtraBackup. The backups are compressed and stored locally, with the option to upload them to AWS S3 for long-term and short-term storage. The scripts are compatible with Ubuntu 22.04 or newer versions and leverage Docker to run Percona XtraBackup 2.4 and AWS CLI.

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
- [Automation](#automation)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Contributions and Feedback](#contributions-and-feedback)
- [Acknowledgments](#acknowledgments)
- [Disclaimer](#disclaimer)

---

## Prerequisites

Before using these scripts, ensure that you have the following installed and configured on your Ubuntu 22.04 system:

- **Docker**: To run Percona XtraBackup and AWS CLI in containers.
- **MySQL 5.7**: The database you intend to back up.

**Note**: The scripts perform all operations within Docker containers, eliminating the need to install additional software on the host system besides Docker.

---

## Setup and Installation

### Clone the Repository

```bash
git clone git@github.com:octeth/octeth-mysql-backup-tool.git
cd innodb-backup-tool
```

### Configure Environment Variables

Create a `.env` file in the root directory of the repository to store configuration variables.

```bash
cp .env.example .env
```

Edit the `.env` file and add your configuration variables. See the [Configuration](#configuration) section for details.

### Run the Installation Script

The `install.sh` script installs Docker (if not already installed) and pulls the required Docker images.

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

- Create a compressed backup of your MySQL data directory using Percona XtraBackup within a Docker container.
- **Optionally** upload the backup to AWS S3 using the AWS CLI Docker image if AWS credentials are provided.
- If AWS credentials are not set, the backup will be stored locally.
- Inform you of the backup file's location if not uploaded to S3.

### Restoring from a Backup

To restore your database from a backup, run the `restore.sh` script.

1. Ensure you have the exact backup file name you wish to restore (e.g., `innodb_backup_2023-10-01_02-00-00.xbstream.gz`).

2. Run the script, passing the backup file name as an argument:

   ```bash
   sudo chmod +x restore.sh
   sudo ./restore.sh innodb_backup_2023-10-01_02-00-00.xbstream.gz
   ```

The script will:

- **Optionally** download the specified backup from AWS S3 if AWS credentials are provided.
- If AWS credentials are not set, it will look for the backup file in the local backup directory.
- Decompress and extract the backup files using Percona XtraBackup within a Docker container.
- Stop the MySQL service or container.
- Clean the existing MySQL data directory.
- Restore the backup to the data directory.
- Adjust file ownership.
- Start the MySQL service or container.
- Clean up the local backup files.

---

## Scripts Overview

### install.sh

This script prepares the environment by:

- **Installing Docker**: Checks if Docker is installed and installs it if necessary.
- **Pulling Docker Images**:
  - `percona/percona-xtrabackup:2.4` for performing backups and restores.
  - `amazon/aws-cli` for AWS S3 interactions.

### backup.sh

This script performs the backup process:

- **Loads Configuration**: Reads variables from the `.env` file.
- **Generates Filenames**: Uses date-based variables for naming the backup files.
- **Creates Backup Directory**: Ensures the local backup directory exists.
- **Performs Backup**: Runs Percona XtraBackup inside a Docker container to create a compressed backup.
- **Uploads to S3 (Optional)**: If AWS credentials are provided, uses the AWS CLI Docker image to upload the backup to AWS S3.
- **Local Backup Retention**: If AWS credentials are not set, the backup remains in the local directory.
- **Cleans Up**: Removes the local backup file after successful upload to S3.

### restore.sh

This script restores the database from a backup:

- **Loads Configuration**: Reads variables from the `.env` file.
- **Downloads Backup (Optional)**: If AWS credentials are provided, uses the AWS CLI Docker image to download the specified backup from S3.
- **Local Backup Usage**: If AWS credentials are not set, the script uses the backup file from the local backup directory.
- **Prepares Backup**: Decompresses and extracts the backup using Percona XtraBackup inside a Docker container.
- **Stops MySQL**: Stops the MySQL service or Docker container.
- **Cleans Data Directory**: Removes existing data in the MySQL data directory.
- **Restores Backup**: Copies the backup data into the MySQL data directory using Percona XtraBackup.
- **Adjusts Ownership**: Sets correct permissions on the data directory.
- **Starts MySQL**: Restarts the MySQL service or Docker container.
- **Cleans Up**: Removes temporary files from the backup directory.

---

## Configuration

### .env File

All configuration variables are stored in the `.env` file located in the root directory of the repository. Below is an example of what the `.env` file should contain:

```bash
# .env file

# AWS S3 Configuration
S3_BUCKET="s3://your-s3-bucket-name"

# Backup Directories
DATA_DIR="/var/lib/mysql"        # Path to your MySQL data directory
BACKUP_DIR="/root/mysql_backups" # Local directory to store backups
MYSQL_DATA_DIR="/var/lib/mysql"  # MySQL data directory for restore

# AWS Credentials (leave empty if not using AWS S3)
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
AWS_DEFAULT_REGION=""

# Backup Storage Configuration
LONGTERM="longterm"    # S3 folder for long-term backups
SHORTTERM="shortterm"  # S3 folder for short-term backups

# MySQL Docker Container Name (if using MySQL in Docker)
MYSQL_CONTAINER_NAME=""  # Set this if MySQL is running in a Docker container
```

**Notes:**

- **AWS Credentials**:
  - If `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, and `AWS_DEFAULT_REGION` are set to empty values, the scripts will skip uploading backups to S3.
  - When restoring, if AWS credentials are not provided, the script will look for the backup file in the local backup directory.
- **Local Backups**:
  - Ensure that your `BACKUP_DIR` has sufficient storage space and is secured appropriately.
- **MySQL Data Directory**:
  - Update the `DATA_DIR` and `MYSQL_DATA_DIR` variables if your MySQL data directory is located elsewhere.
- **MySQL Container**:
  - If your MySQL server is running inside a Docker container, set `MYSQL_CONTAINER_NAME` to the container's name.

---

## Automation

To automate the backup process, you can schedule the `backup.sh` script using `cron`.

### Scheduling Backups with Cron

1. Open the crontab editor:

   ```bash
   sudo crontab -e
   ```

2. Add a cron job to run the backup script at your desired schedule. For example, to run the backup daily at 2 AM:

   ```cron
   0 2 * * * /path/to/innodb-backup-tool/backup.sh >> /var/log/mysql_backup.log 2>&1
   ```

3. Save and exit the crontab editor.

**Note**:

- Ensure that the script paths are correct.
- The user running the cron job must have sufficient permissions to execute the script and access Docker.
- Redirecting output to a log file (`>> /var/log/mysql_backup.log 2>&1`) helps in monitoring the backup process.

---

## Security Considerations

- **Sensitive Data**: Avoid committing the `.env` file to version control if it contains sensitive information.
  - Add `.env` to your `.gitignore` file.
- **File Permissions**: Set appropriate permissions on the `.env` file and backup directories to prevent unauthorized access.

  ```bash
  chmod 600 .env
  chmod -R 700 /root/mysql_backups
  ```

- **AWS Credentials**:
  - If possible, use AWS IAM roles, AWS CLI configuration files, or environment variables instead of hardcoding credentials in the `.env` file.
  - When AWS credentials are not set, backups will not be uploaded to S3; ensure that local backups are secured and managed appropriately.
- **Data Encryption**:
  - For an additional layer of security, consider encrypting your backups before uploading them to S3. AWS S3 supports server-side encryption.
  - Encrypt local backups if they contain sensitive data and are stored on the server.
- **Docker Security**:
  - Ensure that Docker is securely configured and that only authorized users can execute Docker commands.
- **Logging**:
  - Redirect script output to log files and secure them appropriately.
- **Access Control**:
  - Limit access to the server and ensure only trusted personnel can run the scripts.
- **Backup Retention Policy**:
  - Implement a policy for how long local backups are retained if not uploading to S3.
  - Regularly monitor and clean up old backups to manage disk space.

---

## Troubleshooting

- **Backup Fails Immediately**:
  - Check the Docker logs for the `percona/percona-xtrabackup` container.
  - Ensure the `DATA_DIR` path is correct and accessible.
- **AWS S3 Upload Fails**:
  - Verify that AWS credentials are correctly set in the `.env` file.
  - Ensure the S3 bucket name and path are correct.
  - If AWS credentials are not set, the script will skip the upload.
- **Restore Process Issues**:
  - Confirm that the backup file name provided to `restore.sh` matches the backup you intend to restore.
  - Ensure that the MySQL service or container is properly stopped before restoring.
  - If AWS credentials are not set, ensure the backup file exists in the local backup directory.
- **Permission Errors**:
  - Ensure you run the scripts with sufficient privileges (`sudo` may be required).
  - Verify that the `chown` command in `restore.sh` points to the correct user and group (`mysql:mysql`).
- **Docker Errors**:
  - Ensure Docker is running and that you have permission to execute Docker commands.
  - Check for conflicts with container names if multiple backups are run simultaneously.

---

## Contributions and Feedback

Contributions, issues, and feature requests are welcome! Feel free to check the [issues page](https://github.com/cemhurturk/innodb-backup-tool/issues) or submit a pull request.

---

## Acknowledgments

- **Percona XtraBackup**: An open-source hot backup utility for MySQL-based servers.
- **AWS S3**: Scalable storage in the cloud provided by Amazon Web Services.
- **Docker**: A platform for developing, shipping, and running applications in containers.
- **Octeth Email Marketing Software**: The software for which this backup tool was specifically built.

---

## Disclaimer

These scripts are provided as-is without any warranty. Use them at your own risk, and always ensure you have proper backups before performing restore operations.

---

*For any questions or support, please contact [cem.hurturk@gmail.com](mailto:cem.hurturk@gmail.com).*

---

# Thank You

We hope this tool assists you in effectively managing your MySQL backups and restores. Your feedback is invaluable; please don't hesitate to reach out with any suggestions or improvements.

---

# Shortcuts

- **[Back to Top](#mysql-backup-and-restore-scripts-using-percona-xtrabackup-and-aws-s3)**

---

*Happy backing up!*
