#!/bin/bash
# Backup script for multiple PostgreSQL databases

set -e

# Load environment variables
source "$(dirname "$0")/../.env"

# Configuration
BACKUP_DIR="/root/backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
DAY_OF_WEEK=$(date +"%u") # 1-7
POSTGRES_CONTAINER="postgres_db"
POSTGRES_USER="${POSTGRES_SUPERUSER:-postgres}"

# Databases to exclude from backup
EXCLUDE_DBS="postgres template1 template0"

# Setup directories
mkdir -p "$BACKUP_DIR/daily"
mkdir -p "$BACKUP_DIR/weekly"

echo "Starting database backups at $TIMESTAMP"

# Get a list of all databases in the cluster
DATABASES=$(docker exec $POSTGRES_CONTAINER psql -U $POSTGRES_USER -t -c "SELECT datname FROM pg_database WHERE datistemplate = false;")

for DB in $DATABASES; do
    # Trim whitespace
    DB=$(echo $DB | xargs)
    
    # Skip excluded databases
    if [[ " $EXCLUDE_DBS " == *" $DB "* ]]; then
        continue
    fi

    echo "Backing up database: $DB"
    FILENAME="${DB}_${TIMESTAMP}.sql.gz"
    FILEPATH="$BACKUP_DIR/daily/$FILENAME"

    # Run pg_dump inside the container and stream to local gzip
    docker exec -e PGPASSWORD="$POSTGRES_SUPERUSER_PASSWORD" $POSTGRES_CONTAINER \
        pg_dump -U $POSTGRES_USER -d $DB \
        -Fc > "$FILEPATH"

    # Once a week (e.g. Sunday=7), copy the backup to the weekly folder
    if [ "$DAY_OF_WEEK" -eq 7 ]; then
        cp "$FILEPATH" "$BACKUP_DIR/weekly/${DB}_weekly_${TIMESTAMP}.sql.gz"
    fi
     
    # Optional: Sync to S3/DigitalOcean Spaces
    # (Requires aws-cli or s3cmd installed on the host)
    if [ -n "$S3_BUCKET" ] && [ "$S3_BUCKET" != "my-db-backups" ]; then
        echo "Uploading $DB to S3..."
        export AWS_ACCESS_KEY_ID=$S3_ACCESS_KEY
        export AWS_SECRET_ACCESS_KEY=$S3_SECRET_KEY
        aws s3 --endpoint-url=https://$S3_ENDPOINT cp "$FILEPATH" "s3://$S3_BUCKET/daily/$FILENAME"
    fi
done

# Cleanup old backups
# 7 daily backups
find "$BACKUP_DIR/daily" -type f -name "*.sql.gz" -mtime +7 -exec rm {} \;
# 4 weekly backups (28 days)
find "$BACKUP_DIR/weekly" -type f -name "*.sql.gz" -mtime +28 -exec rm {} \;

echo "Backups completed successfully!"
