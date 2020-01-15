#!/bin/bash

envsubst < /root/autoinstall.ini > /tmp/ispconfig3_install/install/autoinstall.ini

echo $isp_hostname > /etc/mailname

cd /tmp/ispconfig3_install/install/

if [ -f /usr/local/ispconfig/interface/lib/config.inc.php ]; 
then
	/wait-for-it.sh master:3306 -- php -q update.php --autoinstall=/tmp/ispconfig3_install/install/autoinstall.ini
else
	/wait-for-it.sh master:3306 -- php -q install.php --autoinstall=/tmp/ispconfig3_install/install/autoinstall.ini
fi

sed -i "s/^hosts .*$/hosts = $isp_mysql_hostname/g" /etc/postfix/mysql-virtual_outgoing_bcc.cf

echo "UPDATE mysql.user SET Host = '%' WHERE User like 'ispc%';" | mysql -u root -h$isp_mysql_hostname -p$isp_mysql_root_password
echo "UPDATE mysql.db SET Host = '%' WHERE User like 'ispc%';" | mysql -u root -h$isp_mysql_hostname -p$isp_mysql_root_password
echo "FLUSH PRIVILEGES;" | mysql -u root -h$isp_mysql_hostname -p$isp_mysql_root_password

chmod 770 /etc/courier/shared/index

rm -rf /var/run/saslauthd
ln -sfn /var/spool/postfix/var/run/saslauthd /var/run/saslauthd

screenfetch

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
