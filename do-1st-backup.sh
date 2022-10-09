#!/usr/bin/env bash


cp -r --parents /var/lib/amavis/ /data/
cp -r --parents /etc/amavis/ /data/
cp -r --parents /etc/letsencrypt/ /data/
cp -r --parents /etc/apache2/sites-available/ /data/
cp -r --parents /etc/apache2/sites-enabled/ /data/
cp -r --parents /usr/local/ispconfig/ /data/
cp -r --parents /etc/cron.d/ /data/
cp -r --parents /etc/bind/ /data/
cp -r --parents /var/vmail/ /data/
cp -r --parents /var/www/ /data/
echo "Backup Completed"