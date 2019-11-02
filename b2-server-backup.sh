#!/bin/bash


if [ ! -d /mnt/grl-storage/ ]
then
	echo "This script requires a '/mnt/grl-storage' folder."
	exit
fi

NOW=$(date +%Y-%m-%d)

# Remove backup files that are a month old
# If running on OS X, the date command is a bit different:
# rm -f $(date -v-1m +%Y%m%d*).gz

cd /mnt/grl-storage/

# delete yesterday's backup folder

rm -rf /mnt/grl-storage/$(date +%Y-%m-%d* --date='1 days ago')

# Backup to B2 Backblaze with rclone

rclone --progress --transfers=25 copy /mnt/grl-storage b2-daily:grl-hosting-daily
