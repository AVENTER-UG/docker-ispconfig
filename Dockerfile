#
#                    ##        .
#              ## ## ##       ==
#           ## ## ## ##      ===
#       /""""""""""""""""\___/ ===
#  ~~~ {~~ ~~~~ ~~~ ~~~~ ~~ ~ /  ===- ~~~
#       \______ o          __/
#         \    \        __/
#          \____\______/
#
#          |          |
#       __ |  __   __ | _  __   _
#      /  \| /  \ /   |/  / _\ |
#      \__/| \__/ \__ |\_ \__  |
#
#
# Ubuntu 18.04, Apache, PHP, MySQL, PureFTPD, BIND, Postfix, Dovecot, Roundcube and ISPConfig 3.1
#
# Link Referência 
# https://www.howtoforge.com/tutorial/perfect-server-ubuntu-18.04-with-apache-php-myqsl-pureftpd-bind-postfix-doveot-and-ispconfig/3/
#

FROM ubuntu:18.04

MAINTAINER Andreas Peters <support@aventer.biz> version: 0.1


ENV isp_mysql_hostname localhost
ENV isp_mysql_root_password default
ENV isp_mysql_ispconfig_password default
ENV isp_mysql_master_root_password default
ENV isp_mysql_master_hostname localhost
ENV isp_admin_password default
ENV isp_enable_mail n
ENV isp_enable_jailkit n
ENV isp_enable_ftp n
ENV isp_enable_dns y
ENV isp_enable_apache y
ENV isp_enable_nginx y
ENV isp_enable_firewall y
ENV isp_enable_webinterface y
ENV isp_enable_multiserver n
ENV isp_hostname localhost
ENV isp_cert_hostname localhost
ENV isp_use_ssl y

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get -y update && apt-get -y upgrade
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install quota mysql-client wget curl vim rsyslog rsyslog-relp logrotate supervisor screenfetch apt-utils gettext-base

# Remove sendmail
RUN echo -n "Removing Sendmail... "	service sendmail stop hide_output update-rc.d -f sendmail remove apt_remove sendmail

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
      
# Workaround maildrop install  bug
RUN touch /usr/share/man/man5/maildir.maildrop.5.gz \
    && touch /usr/share/man/man7/maildirquota.maildrop.7.gz \
    && apt-get install -y maildrop

RUN apt-get -y install postfix mysql-client postfix-mysql postfix-doc openssl getmail4 rkhunter binutils courier-authlib-mysql courier-pop courier-pop-ssl courier-imap courier-imap-ssl libsasl2-2 libsasl2-modules libsasl2-modules-sql sasl2-bin libpam-mysql sudo gamin
ADD ./etc/postfix/master.cf /etc/postfix/master.cf
ADD ./etc/security/limits.conf /etc/security/limits.conf
ADD ./etc/courier/markerline /tmp/markerline
RUN service postfix stop 
RUN update-rc.d -f postfix remove 

# Install Amavisd-new, SpamAssassin And Clamav
RUN apt-get -y install amavisd-new spamassassin clamav clamav-daemon unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl postgrey
ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf
RUN service spamassassin stop 
RUN update-rc.d -f spamassassin remove

# Install Apache2, PHP5, FCGI, suExec, Pear, And mcrypt
RUN echo $(grep $(hostname) /etc/hosts | cut -f1) localhost >> /etc/hosts && apt-get -y install apache2 apache2-doc apache2-utils libapache2-mod-php php7.2 php7.2-common php7.2-gd php7.2-mysql php7.2-imap php7.2-cli php7.2-cgi libapache2-mod-fcgid apache2-suexec-pristine php-pear mcrypt  imagemagick libruby libapache2-mod-python php7.2-curl php7.2-intl php7.2-pspell php7.2-recode php7.2-sqlite3 php7.2-tidy php7.2-xmlrpc php7.2-xsl memcached php-memcache php-imagick php-gettext php7.2-zip php7.2-mbstring php-soap php7.2-soap
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && a2enconf servername
ADD ./etc/apache2/conf-available/httpoxy.conf /etc/apache2/conf-available/httpoxy.conf
RUN a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi headers && a2enconf httpoxy && a2dissite 000-default && service apache2 restart

# PHP Opcode cache
RUN apt-get -y install php7.2-opcache php-apcu

# PHP-FPM
RUN apt-get -y install php7.2-fpm
RUN a2enmod actions proxy_fcgi alias 
RUN service apache2 stop
RUN update-rc.d -f apache2 remove

# Install BIND DNS Server
RUN apt-get -y install bind9 dnsutils haveged
# deactivate ipv6
RUN sed -i 's/-u bind/-u bind -4/g' /etc/default/bind9
RUN service haveged start
RUN service bind9 stop
RUN update-rc.d -f bind9 remove


# Install Vlogger, Webalizer, and AWStats
RUN apt-get -y install vlogger webalizer awstats geoip-database libclass-dbi-mysql-perl
ADD etc/cron.d/awstats /etc/cron.d/

# Install Jailkit
RUN apt-get -y install build-essential autoconf automake libtool flex bison debhelper binutils
RUN cd /tmp \
&& wget http://olivier.sessink.nl/jailkit/jailkit-2.19.tar.gz \
&& tar xvfz jailkit-2.19.tar.gz \
&& cd jailkit-2.19 \
&& echo 5 > debian/compat \
&& ./debian/rules binary \
&& cd /tmp \
&& rm -rf jailkit-2.19*

# Install fail2ban
RUN apt-get -y install fail2ban
ADD ./etc/fail2ban/jail.local /etc/fail2ban/jail.local
ADD ./etc/fail2ban/filter.d/pureftpd.conf /etc/fail2ban/filter.d/pureftpd.conf
ADD ./etc/fail2ban/filter.d/postfix-sasl.conf /etc/fail2ban/filter.d/postfix-sasl.conf

# Install Let's Encrypt
RUN apt-get -y install python-certbot-apache

# UFW firewall
RUN apt-get install ufw

# ISPCONFIG Initialization and Startup Script
ADD ./wait-for-it.sh /wait-for-it.sh
ADD ./autoinstall.ini /root/autoinstall.ini
ADD ./start.sh /start.sh
ADD ./supervisord.conf /etc/supervisor/supervisord.conf
ADD ./etc/cron.daily/sql_backup.sh /etc/cron.daily/sql_backup.sh

# Install ISPConfig 3
RUN cd /tmp \
&& wget -O ISPConfig.tgz https://ispconfig.org/downloads/ISPConfig-3.1.15p2.tar.gz \
&& tar xfz ISPConfig.tgz

ADD ./update.php /tmp/ispconfig3_install/install/update.php
ADD ./install.php /tmp/ispconfig3_install/install/install.php

ADD ./etc/postfix/master.cf /etc/postfix/master.cf
ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf

RUN echo "export TERM=xterm" >> /root/.bashrc

EXPOSE 53 80/tcp 443/tcp 953/tcp 8080/tcp 30000 30001 30002 30003 30004 30005 30006 30007 30008 30009 3306



RUN chmod 755 /start.sh
RUN mkdir -p /var/run/sshd
RUN mkdir -p /var/log/supervisor
ADD ./bin/systemctl /bin/systemctl
RUN mkdir -p /var/backup/sql

RUN ln -s /dev/urandom /root/.rnd
RUN rm -rf /dev/random \
    && ln -s /dev/urandom /dev/random

VOLUME ["/usr/local/ispconfig/"]

CMD ["/bin/bash", "/start.sh"]
