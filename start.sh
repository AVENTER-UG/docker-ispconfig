#!/bin/bash

envsubst < /root/autoinstall.ini > /tmp/ispconfig3_install/install/autoinstall.ini

if [ ! -f /usr/local/ispconfig/interface/lib/config.inc.php ]; then	
	php -q /tmp/ispconfig3_install/install/install.php --autoinstall=/tmp/ispconfig3_install/install/autoinstall.ini
	echo "" > /var/www/html/index.html
fi

if [ ! -z "$DEFAULT_EMAIL_HOST" ]; then
	sed -i "s/^\(DEFAULT_EMAIL_HOST\) = .*$/\1 = '$MAILMAN_EMAIL_HOST'/g" /etc/mailman/mm_cfg.py
	newlist -q mailman $(MAILMAN_EMAIL) $(MAILMAN_PASS)
	newaliases
fi
if [ ! -z "$LANGUAGE" ]; then
	sed -i "s/^language=en$/language=$LANGUAGE/g" /tmp/ispconfig3_install/install/autoinstall.ini
fi
if [ ! -z "$COUNTRY" ]; then
	sed -i "s/^ssl_cert_country=AU$/ssl_cert_country=$COUNTRY/g" /tmp/ispconfig3_install/install/autoinstall.ini
fi
if [ ! -z "$HOSTNAME" ]; then
	sed -i "s/^hostname=server1.example.com$/hostname=$HOSTNAME/g" /tmp/ispconfig3_install/install/autoinstall.ini
fi

cd /tmp/ispconfig3_install/install/
php -q update.php --autoinstall=/tmp/ispconfig3_install/install/autoinstall.ini
echo "UPDATE mysql.user SET Host = '%' WHERE User = 'ispconfig';" | mysql -u root -h$isp_mysql_hostname -p$isp_mysql_root_password
echo "FLUSH PRIVILEGES;" | mysql -u root -h$isp_mysql_hostname -p$isp_mysql_root_password

screenfetch

/usr/bin/supervisord -c /etc/supervisor/supervisord.conf
