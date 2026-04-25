#!/bin/bash
# Restore a specific PostgreSQL database backup

set -e

source "$(dirname "$0")/../.env"

POSTGRES_CONTAINER="postgres_db"
POSTGRES_USER="${POSTGRES_SUPERUSER:-postgres}"

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <database_name> <path_to_backup_file>"
    echo "Example: $0 male_land_survey_prod /root/backups/daily/male_land_survey_prod_202X-XX-XX.sql.gz"
    exit 1
fi

TARGET_DB=$1
BACKUP_FILE=$2

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file '$BACKUP_FILE' not found!"
    exit 1
fi

echo "=========================================="
echo "WARNING: This will overwrite data in '$TARGET_DB'"
echo "Make sure no applications are currently connected."
echo "=========================================="
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "Operation cancelled."
    exit 1
fi

echo "Restoring database '$TARGET_DB' from '$BACKUP_FILE'..."

# Depending on if it's custom format (-Fc) or plain sql gzip. 
# Our backup.sh uses -Fc for custom format, so pg_restore is best.
docker exec -i -e PGPASSWORD="$POSTGRES_SUPERUSER_PASSWORD" $POSTGRES_CONTAINER \
    pg_restore -U $POSTGRES_USER -d $TARGET_DB --clean --if-exists < "$BACKUP_FILE"

echo "Restore completed successfully!"
