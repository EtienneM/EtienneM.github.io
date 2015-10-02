#/bin/bash
# Thanks to the lovely blog post from basicallyTech: http://www.basicallytech.com/blog/?/archives/73-Using-a-USB-external-hard-disk-for-backups-with-Linux.html#cons_mount

echo "============================================================================="
echo "Backup Owncloud data at " `date`

MYSQL_PWD="TODO"
MOUNT_POINT="/mnt/backup"
MOUNT_DIRECTORY="$MOUNT_POINT/raspberrypi"
MOUNT_DB_DIRECTORY="$MOUNT_DIRECTORY/db"
OWNCLOUD_DATA="/home/webserver/owncloud-data"
OWNCLOUD_DIR="/home/webserver/www/owncloud"
DB_BACKUP_DIRECTORY="/home/emichon/mysqldump"
DB_BACKUP="$DB_BACKUP_DIRECTORY/dump.sql"
NB_DB_BACKUP=5
ERROR_LOG="/tmp/error-backup.log"

if [ ! -d $OWNCLOUD_DATA ]; then
	echo "Nothing to backup" >&2
	exit 255
fi

#===============================
# Check if the backup is mounted
#===============================
mountpoint -q $MOUNT_POINT
if [ $? -eq 1 ]; then
	echo "Mouting $MOUNT_POINT"
	mount $MOUNT_POINT
	if [ $? -ne 0 ]; then
		echo "Cannot mount the backup drive" >&2
		exit 254
	fi
fi
if [ ! -d $MOUNT_DIRECTORY ]; then
	echo "Create $MOUNT_DIRECTORY"
	mkdir $MOUNT_DIRECTORY
fi

#========================
# Dump the mysql database
#========================
if [ ! -d $DB_BACKUP_DIRECTORY ]; then
	echo "Create $DB_BACKUP_DIRECTORY"
	mkdir $DB_BACKUP_DIRECTORY
fi
if [ ! -d $MOUNT_DB_DIRECTORY ]; then
	echo "Create $MOUNT_DB_DIRECTORY"
	mkdir $MOUNT_DB_DIRECTORY
fi
echo "Dump the database into $DB_BACKUP"
/usr/local/mysql/bin/mysqldump --lock-tables --user=root --password=${MYSQL_PWD} owncloud > $DB_BACKUP 2> $ERROR_LOG
if [[ $? -ne 0 ]]; then
	if [[ ! -f $ERROR_LOG ]]; then
		echo "No error message" > $ERROR_LOG
	fi
	cat $ERROR_LOG | mail -s "Database backup failed" titizebioutifoul@free.fr
	cat $ERROR_LOG
	rm $ERROR_LOG
fi
echo "Compress the database backup"
gzip --force $DB_BACKUP
echo "Save the database backup into the remote storage"
cp $DB_BACKUP.gz $MOUNT_DB_DIRECTORY/dump_$(date +%s).sql.gz
while [[ $(ls -l $MOUNT_DB_DIRECTORY/dump_*.sql.gz | wc -l) -gt $NB_DB_BACKUP ]]; do
	OLDEST_BACKUP=$(find $MOUNT_DB_DIRECTORY/dump_*.sql.gz -type f -printf '%T+ %p\n'  | sort | head -n 1 | cut -d' ' -f2)
	echo "Delete the oldest backup $OLDEST_BACKUP"
	rm $OLDEST_BACKUP
done


#===============
# Run the backup
#===============
echo "Backup owncloud data"
# -v   verbose
# -r   recurse into directories
# -l   copy symlinks as symlinks
# -p   preserve permissions
# -t   preserve times
# -g   preserve group
rsync -vrlptg $OWNCLOUD_DATA $MOUNT_DIRECTORY --exclude='owncloud-data/*/files*' --exclude='*/cache/*' --exclude='*/thumbnails/*' --exclude='*/lucene_index/*' 2> $ERROR_LOG
if [[ $? -ne 0 ]]; then
	if [[ ! -f $ERROR_LOG ]]; then
		echo "No error message" > $ERROR_LOG
	fi
	cat $ERROR_LOG | mail -s "Owncloud backup failed" titizebioutifoul@free.fr
	cat $ERROR_LOG
	rm $ERROR_LOG
fi
cp $OWNCLOUD_DIR/config/config.php $MOUNT_DIRECTORY

#========================
# Unmount the backup disk
#========================
echo "Un-mount $MOUNT_POINT"
umount "$MOUNT_POINT"

echo "End of backup"
echo "============================================================================="
