#!/bin/bash

echo $(grep $(hostname) /etc/hosts | cut -f1) localhost >> /etc/hosts

envsubst < /root/autoinstall.ini > /tmp/ispconfig3_install/install/autoinstall.ini

echo $isp_hostname > /etc/mailname

cd /tmp/ispconfig3_install/install/

if [ -f /usr/local/ispconfig/interface/lib/config.inc.php ]; 
then
  # Fixed: Table already exists
  rm /tmp/ispconfig3_install/install/sql/incremental/upd_dev_collection.sql
	/wait-for-it.sh $isp_mysql_hostname:$isp_mysql_port -- php -q update.php --autoinstall=/tmp/ispconfig3_install/install/autoinstall.ini
else
	/wait-for-it.sh $isp_mysql_hostname:$isp_mysql_port -- php -q install.php --autoinstall=/tmp/ispconfig3_install/install/autoinstall.ini
fi

# Fix from amavis ownerchip that prevents amavis to start
chown -R amavis: /var/lib/amavis/

#sed -i "s/^hosts .*$/hosts = $isp_mysql_hostname/g" /etc/postfix/mysql-virtual_outgoing_bcc.cf
sed -i "s/^myhostname = .*$/myhostname = $isp_hostname/g" /etc/postfix/main.cf
echo message_size_limit=52428800 >> /etc/postfix/main.cf

#echo "UPDATE mysql.user SET Host = '%' WHERE User like 'ispc%';" | mysql -u root -h$isp_mysql_hostname -p$isp_mysql_root_password
#echo "UPDATE mysql.db SET Host = '%' WHERE User like 'ispc%';" | mysql -u root -h$isp_mysql_hostname -p$isp_mysql_root_password
#echo "FLUSH PRIVILEGES;" | mysql -u root -h$isp_mysql_hostname -p$isp_mysql_root_password

# Bugfix ISPconfig mysql error
echo "ALTER TABLE dbispconfig.sys_user MODIFY passwort VARCHAR(140);"  | mysql -u root -h$isp_mysql_hostname -P$isp_mysql_port -p$isp_mysql_root_password
echo "FLUSH PRIVILEGES;" | mysql -u root -h$isp_mysql_hostname -P$isp_mysql_port -p$isp_mysql_root_password

# Bugfix ISPconfig missing markerline
envsubst < /root/authmysqlrc.ini > /etc/courier/authmysqlrc

# configure phpmyadmin
envsubst < /root/phpmyadmin.ini > /etc/phpmyadmin/config.inc.php

mkdir -p /etc/courier/shared/index
chmod -R 770 /etc/courier/shared

rm -rf /var/run/saslauthd
ln -sfn /var/spool/postfix/var/run/saslauthd /var/run/saslauthd

screenfetch

/etc/init.d/clamav-daemon start

if [ "$isp_enable_mail" == "y" ];
then
  /etc/init.d/courier-authdaemon start
fi

if [ "$isp_enable_dns" == "y" ];
then
  /etc/init.d/named start
fi

if [ "$isp_enable_nginx" == "y" ];
then
  /etc/init.d/php8.1-fpm start
fi

if [ "$isp_enable_apache" == "y" ];
then
  /etc/init.d/php8.1-fpm start
fi

if [ "$isp_enable_jailkit" == "y" ];
then
  /etc/init.d/sshd start
fi

/etc/init.d/cron restart

unset isp_mysql_root_password
unset isp_mysql_ispconfig_password
unset isp_mysql_master_root_password
unset isp_admin_password
unset isp_mysql_database

# fix rncd erro
chown root:bind /etc/bind/rndc.key
# fix index permission error
chown courier: /etc/courier/shared/index

if [ -f "/var/backup/1st-backup-complete.log" ]; 
then 
    echo "1st Backup file exists. Nothing to do here" 
else 
    /do-1st-backup.sh &
fi

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
