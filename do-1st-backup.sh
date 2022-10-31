#!/usr/bin/env bash

output=/var/backup/1st-backup-complete.log

#sleep 30
#echo "Waiting for 30 sec to ensure install is completed before doing the backup"

if [ ! -f "$output" ]
then
    echo "Waiting for 30 sec to ensure install is completed before doing the backup" 
    sleep 30 
    cp -r --parents /var/lib/amavis/ /data_tmp/
    echo "/var/lib/amavis/ backed up 1st time" >>  $output
    cp -r --parents /etc/amavis/ /data_tmp/
    echo "/etc/amavis/ backed up 1st time" >>  $output
    cp -r --parents /etc/letsencrypt/ /data_tmp/
    echo "/etc/letsencrypt/ backed up 1st time" >>  $output
    cp -r --parents /etc/apache2/sites-available/ /data_tmp/
    echo "/etc/apache2/sites-available/ backed up 1st time" >>  $output
    cp -r --parents /etc/apache2/sites-enabled/ /data_tmp/
    echo "/etc/apache2/sites-enabled/ backed up 1st time" >>  $output
    cp -r --parents /usr/local/ispconfig/ /data_tmp/
    echo "/usr/local/ispconfig/ backed up 1st time" >>  $output
    cp -r --parents /etc/cron.d/ /data_tmp/
    echo "/etc/cron.d/ backed up 1st time" >>  $output
    cp -r --parents /etc/bind/ /data_tmp/
    echo "/etc/bind/ backed up 1st time" >>  $output
    cp -r --parents /var/vmail/ /data_tmp/
    echo "/var/vmail/ backed up 1st time" >>  $output
    cp -r --parents /var/www/ /data_tmp/
    echo "/var/www/ backed up 1st time" >>  $output
    dt=$(date '+%d/%m/%Y %H:%M:%S');
    echo "1st Backup Completed $dt" >>  $output
    echo "1st Backup Completed $dt" 
else
    echo "Backup log File found. No backup required, change to Persist Data"
fi