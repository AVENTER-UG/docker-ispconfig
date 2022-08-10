#!/usr/bin/env bash
#   Use this script to test if a given TCP host/port are available

cp -r --parents /var/lib/amavis/ /var/backup/
cp -r --parents /etc/amavis/ /var/backup/
cp -r --parents /etc/letsencrypt/ /var/backup/
cp -r --parents /etc/apache2/sites-available/ /var/backup/
cp -r --parents /etc/apache2/sites-enabled/ /var/backup/
cp -r --parents /usr/local/ispconfig/ /var/backup/
cp -r --parents /etc/cron.d/ /var/backup/
cp -r --parents /etc/bind/ /var/backup/
cp -r --parents /var/vmail/ /var/backup/
cp -r --parents /var/www/ /var/backup/
echo "Backup Completed"