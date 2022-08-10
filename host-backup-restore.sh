#!/usr/bin/env bash

sudo cp -r --parents /data/panel/backup/var/lib/amavis/ /data/panel/
sudo cp -r --parents /data/panel/backup/etc/amavis/ /data/panel/
sudo cp -r --parents /data/panel/backup/etc/letsencrypt/  /data/panel/
sudo cp -r --parents /data/panel/backup/etc/apache2/sites-available/ /data/panel/
sudo cp -r --parents /data/panel/backup/etc/apache2/sites-enabled/ /data/panel/
sudo cp -r --parents /data/panel/backup/usr/local/ispconfig/ /data/panel/
sudo cp -r --parents /data/panel/backup/etc/cron.d/ /data/panel/
sudo cp -r --parents /data/panel/backup/etc/bind/ /data/panel/
sudo cp -r --parents /data/panel/backup/var/vmail/ /data/panel/
sudo cp -r --parents /data/panel/backup/var/www/ /data/panel/

echo "Backup Restored on Host"