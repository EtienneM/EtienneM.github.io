#/bin/bash
# Thanks to the lovely blog post from basicallyTech: http://www.basicallytech.com/blog/?/archives/73-Using-a-USB-external-hard-disk-for-backups-with-Linux.html#cons_mount

echo "============================================================================="
echo "Backup Owncloud data at " `date`

MOUNT_POINT="/mnt/backup"
MOUNT_DIRECTORY="$MOUNT_POINT/raspberrypi"
OWNCLOUD_DATA="/home/webserver/owncloud-data"
OWNCLOUD_DIR="/home/webserver/www/owncloud"
MYSQL_BACKUP_DIRECTORY="/home/emichon/mysqldump"
MYSQL_BACKUP="$MYSQL_BACKUP_DIRECTORY/dump.sql"

if [ ! -d $OWNCLOUD_DATA ]; then
	echo "Nothing to backup" >&2
	exit 255
fi

#========================
# Dump the mysql database
#========================
if [ ! -d $MYSQL_BACKUP_DIRECTORY ]; then
	echo "Create $MYSQL_BACKUP_DIRECTORY"
	mkdir $MYSQL_BACKUP_DIRECTORY
fi
echo "Dump the mysql database into $MYSQL_BACKUP"
mysqldump --lock-tables --user=root --password=TODO_PASSWORD owncloud > $MYSQL_BACKUP

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

#===============
# Run the backup
#===============
echo "Backup"
# -v   verbose
# -r   recurse into directories
# -l   copy symlinks as symlinks
# -p   preserve permissions
# -t   preserve times
# -g   preserve group
rsync -vrlptg $OWNCLOUD_DATA $MYSQL_BACKUP $MOUNT_DIRECTORY --exclude='owncloud-data/*/files*' --exclude='*/cache/*' --exclude='*/lucene_index/*'
cp $OWNCLOUD_DIR/config/config.php $MOUNT_DIRECTORY

#========================
# Unmount the backup disk
#========================
echo "Un-mount $MOUNT_POINT"
umount "$MOUNT_POINT"

echo "End of backup"
echo "============================================================================="
