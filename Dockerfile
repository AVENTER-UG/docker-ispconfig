FROM ubuntu:jammy

LABEL maintainer="Andreas Peters <support@aventer.biz>"
LABEL org.opencontainers.image.title="docker-ispconfig"
LABEL org.opencontainers.image.description="This docker image include a whole ISPConfig3 software stack!"
LABEL org.opencontainers.image.vendor="AVENTER UG (haftungsbeschränkt)"
LABEL org.opencontainers.image.source="https://github.com/AVENTER-UG/docker-ispconfig"

ARG TAG_SYN=v3.2.11p2

ENV isp_mysql_hostname master
ENV isp_mysql_port 3306
ENV isp_mysql_root_user root
ENV isp_mysql_root_password default
ENV isp_mysql_database dbispconfig
ENV isp_mysql_ispconfig_password default
ENV isp_mysql_master_root_user root
ENV isp_mysql_master_root_password default
ENV isp_mysql_master_hostname localhost
ENV isp_mysql_master_database dbispconfig
ENV isp_admin_password default
ENV isp_enable_mail n
ENV isp_enable_jailkit n
ENV isp_enable_ftp n
ENV isp_enable_dns y
ENV isp_enable_apache y
ENV isp_enable_nginx n
ENV isp_enable_firewall y
ENV isp_enable_webinterface y
ENV isp_enable_multiserver n
ENV isp_hostname localhost
ENV isp_cert_hostname localhost
ENV isp_use_ssl y
ENV isp_change_mail_server y
ENV isp_change_web_server y
ENV isp_change_dns_server y
ENV isp_change_xmpp_server y
ENV isp_change_firewall_server y
ENV isp_change_vserver_server y
ENV isp_change_db_server y
ENV firewall_server_enabled n
ENV xmpp_server_enabled n
ENV isp_postfix_protocols ipv4


ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install quota quotatool software-properties-common quota mysql-client wget curl vim rsyslog rsyslog-relp logrotate supervisor screenfetch apt-utils gettext-base git

# Remove sendmail
RUN echo -n "Removing Sendmail... "	service sendmail stop hide_output update-rc.d -f sendmail remove apt_remove sendmail

# Install OpenSSH 
RUN apt-get -y install ssh openssh-server rsync


# Install Postfix, Dovecot, rkhunter, binutils
RUN echo -n "Installing SMTP Mail server (Postfix)... " \
RUN apt-get install -y courier-authdaemon courier-authlib courier-authlib-userdb 
# workaround courier install bug
RUN touch /usr/share/man/man5/maildir.courier.5.gz  \
    && touch /usr/share/man/man8/deliverquota.courier.8.gz \
    && touch /usr/share/man/man1/maildirmake.courier.1.gz \
    && touch /usr/share/man/man7/maildirquota.courier.7.gz \
    && touch /usr/share/man/man1/makedat.courier.1.gz \
    && ls -l /usr/share/man/man7/ \
    && apt-get -y install courier-base

# Install PhpMyAdmin
RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/admin-pass password pass' | debconf-set-selections
RUN apt-get -y install phpmyadmin    
ADD ./etc/phpmyadmin/phpmyadmin.ini /root/phpmyadmin.ini
      
# Workaround maildrop install  bug
RUN touch /usr/share/man/man5/maildir.maildrop.5.gz \
    && touch /usr/share/man/man7/maildirquota.maildrop.7.gz \
    && apt-get install -y maildrop

RUN apt-get -y install postfix mysql-client postfix-mysql postfix-doc openssl getmail6 rkhunter binutils courier-authlib-mysql courier-pop courier-pop courier-imap courier-imap libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql sudo gamin
ADD ./etc/postfix/master.cf /etc/postfix/master.cf
ADD ./etc/security/limits.conf /etc/security/limits.conf
ADD ./etc/courier/authmysqlrc.ini /root/authmysqlrc.ini
RUN service postfix stop 

# Install Amavisd-new, SpamAssassin And Clamav
RUN apt-get -y install amavisd-new spamassassin clamav clamav-daemon unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl postgrey
ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf
RUN service spamassassin stop 
RUN service clamav-daemon stop 
# Install Apache2, PHP, FCGI, suExec, Pear, And mcrypt
RUN apt-get -y install apache2 apache2-doc apache2-utils libapache2-mod-php php8.1 php8.1-common php8.1-gd php8.1-mysql php8.1-imap php8.1-cli php8.1-cgi libapache2-mod-fcgid apache2-suexec-pristine php-pear mcrypt  imagemagick libruby libapache2-mod-python php8.1-curl php8.1-intl php8.1-pspell php8.1-sqlite3 php8.1-tidy php8.1-xmlrpc php8.1-xsl memcached php-memcache php-imagick php8.1-zip php8.1-mbstring php-soap php8.1-soap
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && a2enconf servername
ADD ./etc/apache2/conf-available/httpoxy.conf /etc/apache2/conf-available/httpoxy.conf
RUN a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi headers && a2enconf httpoxy && a2dissite 000-default && service apache2 restart

# PHP Opcode cache
RUN apt-get -y install php8.1-opcache php-apcu

# PHP 7.4 FPM
RUN apt-get -y install php8.1-fpm

RUN a2enmod actions proxy_fcgi alias 
RUN service apache2 stop


# Install BIND DNS Server
RUN apt-get -y install bind9 dnsutils haveged
# deactivate ipv6
RUN sed -i 's/-u bind/-u bind -4/g' /etc/default/named
RUN service haveged start
RUN service named stop


# Install Vlogger, Webalizer, and AWStats
RUN apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl
ADD etc/cron.d/awstats /etc/cron.d/

# Install Jailkit
RUN apt-get -y install build-essential autoconf automake libtool flex bison debhelper binutils python3 jailkit

# Install fail2ban
RUN apt-get -y install fail2ban 
ADD ./etc/fail2ban/jail.local /etc/fail2ban/jail.local
ADD ./etc/fail2ban/filter.d/* /etc/fail2ban/filter.d/

# Install Let's Encrypt
RUN apt-get -y install python3-certbot-apache

# UFW firewall
RUN apt-get -y install ufw

# ISPCONFIG Initialization and Startup Script
ADD ./wait-for-it.sh /wait-for-it.sh
ADD ./autoinstall.ini /root/autoinstall.ini
ADD ./start.sh /start.sh
ADD ./supervisord.conf /etc/supervisor/supervisord.conf
ADD ./etc/rsyslog/rsyslog.conf /etc/rsyslog.conf
ADD ./etc/cron.daily/sql_backup.sh /etc/cron.daily/sql_backup.sh

# Install ISPConfig 3
RUN git clone --branch $TAG_SYN --depth 1 https://github.com/AVENTER-UG/ispconfig3.git /tmp/ispconfig3_install
#COPY ispconfig3 /tmp/ispconfig3_install

ADD ./update.php /tmp/ispconfig3_install/install/update.php
ADD ./install.php /tmp/ispconfig3_install/install/install.php

ADD ./etc/postfix/master.cf /etc/postfix/master.cf

ADD ./etc/postfix/client_checks /etc/postfix/client_checks
RUN postmap /etc/postfix/client_checks

ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf

RUN echo "export TERM=xterm" >> /root/.bashrc

EXPOSE 53 80/tcp 443/tcp 953/tcp 8080/tcp 30000 30001 30002 30003 30004 30005 30006 30007 30008 30009 $isp_mysql_port



RUN chmod 755 /start.sh
RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor
ADD ./bin/systemctl /bin/systemctl
RUN mkdir -p /var/backup/sql
RUN mkdir -p /var/spool/postfix/private
RUN touch /var/spool/postfix/private/quota-status
RUN chown postfix:root /var/spool/postfix/private
RUN chown postfix:postfix /var/spool/postfix/private/quota-status
RUN chmod 0660 /var/spool/postfix/private/quota-status

RUN ln -s /dev/urandom /root/.rnd
RUN rm -rf /dev/random \
    && ln -s /dev/urandom /dev/random

RUN chmod 755 /var/log

## logrotate woradounds
ADD ./etc/logrotate/rsyslog-rotate /usr/lib/rsyslog/rsyslog-rotate 

VOLUME ["/usr/local/ispconfig/"]

## Initial Backup
ADD ./do-1st-backup.sh /do-1st-backup.sh

## FIX: mysqldump Error: Unknown table ‘COLUMN_STATISTICS’ in information_schema (1109)
RUN echo "column-statistics=0" >> /etc/mysql/conf.d/mysqldump.cnf 

RUN echo START="yes" >> /etc/default/saslauthd

## FIX: Postgrey listening interface
ADD ./etc/default/postgrey /etc/default/postgrey

CMD ["/bin/bash", "/start.sh"]
