FROM ubuntu:noble

LABEL maintainer="Andreas Peters <support@aventer.biz>"
LABEL org.opencontainers.image.title="docker-ispconfig"
LABEL org.opencontainers.image.description="This docker image include a whole ISPConfig3 software stack!"
LABEL org.opencontainers.image.vendor="AVENTER UG (haftungsbeschränkt)"
LABEL org.opencontainers.image.source="https://github.com/AVENTER-UG/docker-ispconfig"

ARG TAG_SYN=master

ENV isp_mysql_hostname=master
ENV isp_mysql_port=3306
ENV isp_mysql_root_user=root
ENV isp_mysql_root_password=default
ENV isp_mysql_database=dbispconfig
ENV isp_mysql_ispconfig_password=default
ENV isp_mysql_master_root_user=root
ENV isp_mysql_master_root_password=default
ENV isp_mysql_master_hostname=localhost
ENV isp_mysql_master_database=dbispconfig
ENV isp_admin_password=default
ENV isp_enable_mail=n
ENV isp_enable_jailkit=n
ENV isp_enable_ftp=n
ENV isp_enable_dns=y
ENV isp_enable_apache=y
ENV isp_enable_nginx=y
ENV isp_enable_firewall=y
ENV isp_enable_webinterface=y
ENV isp_enable_multiserver=n
ENV isp_hostname=localhost
ENV isp_cert_hostname=localhost
ENV isp_use_ssl=y
ENV isp_change_mail_server=y
ENV isp_change_web_server=y
ENV isp_change_dns_server=y
ENV isp_change_xmpp_server=y
ENV isp_change_firewall_server=y
ENV isp_change_vserver_server=y
ENV isp_change_db_server=y
ENV isp_postfix_protocols=ipv4

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -y update && apt-get -y upgrade && apt-get -y install quota quotatool software-properties-common quota mysql-client wget curl vim rsyslog rsyslog-relp logrotate supervisor screenfetch apt-utils gettext-base git

# Install OpenSSH 
RUN apt-get -y install ssh openssh-server rsync


# Install Postfix, Dovecot, rkhunter, binutils
RUN echo -n "Installing SMTP Mail server (Postfix)... " && apt-get install -y courier-authdaemon courier-authlib courier-authlib-userdb
# workaround courier install bug
RUN touch /usr/share/man/man5/maildir.courier.5.gz  \
    && touch /usr/share/man/man8/deliverquota.courier.8.gz \
    && touch /usr/share/man/man1/maildirmake.courier.1.gz \
    && touch /usr/share/man/man7/maildirquota.courier.7.gz \
    && touch /usr/share/man/man1/makedat.courier.1.gz \
    && ls -l /usr/share/man/man7/



# Install PhpMyAdmin
RUN echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
RUN echo 'phpmyadmin phpmyadmin/mysql/admin-pass password pass' | debconf-set-selections
RUN apt-get -y install phpmyadmin    
ADD ./etc/phpmyadmin/phpmyadmin.ini /root/phpmyadmin.ini
      
# Workaround maildrop install  bug
RUN touch /usr/share/man/man5/maildir.maildrop.5.gz \
    && touch /usr/share/man/man7/maildirquota.maildrop.7.gz

RUN apt-get -y install postfix mysql-client postfix-mysql postfix-doc openssl \
		getmail6 rkhunter binutils courier-authlib-mysql libsasl2-2 libsasl2-modules \
		libsasl2-modules-sql sasl2-bin libpam-mysql sudo
ADD ./etc/postfix/master.cf /etc/postfix/master.cf
ADD ./etc/security/limits.conf /etc/security/limits.conf
ADD ./etc/courier/authmysqlrc.ini /root/authmysqlrc.ini
RUN service postfix stop 

# Install Amavisd-new, SpamAssassin And Clamav
RUN apt-get -y install amavisd-new spamassassin clamav clamav-daemon unzip bzip2 arj nomarch lzop cabextract apt-listchanges libnet-ldap-perl libauthen-sasl-perl clamav-docs daemon libio-string-perl libio-socket-ssl-perl libnet-ident-perl zip libnet-dns-perl postgrey
ADD ./etc/clamav/clamd.conf /etc/clamav/clamd.conf
RUN service clamav-daemon stop 
# Install Apache2, PHP, FCGI, suExec, Pear, And mcrypt
RUN apt-get -y install apache2 apache2-doc apache2-utils libapache2-mod-php php8.3 php8.3-common php8.3-gd php8.3-mysql php8.3-imap php8.3-cli php8.3-cgi libapache2-mod-fcgid apache2-suexec-pristine php-pear mcrypt imagemagick libruby libapache2-mod-python php8.3-curl php8.3-intl php8.3-pspell php8.3-sqlite3 php8.3-tidy php8.3-xmlrpc php8.3-xsl memcached php-memcache php-imagick php8.3-zip php8.3-mbstring php-soap php8.3-soap
RUN echo "ServerName localhost" > /etc/apache2/conf-available/servername.conf && a2enconf servername
ADD ./etc/apache2/conf-available/httpoxy.conf /etc/apache2/conf-available/httpoxy.conf
RUN a2enmod suexec rewrite ssl actions include dav_fs dav auth_digest cgi headers && a2enconf httpoxy && a2dissite 000-default && service apache2 restart

# PHP Opcode cache
RUN apt-get -y install php8.3-opcache php-apcu

# PHP-FPM
RUN apt-get -y install php8.3-fpm

RUN a2enmod actions proxy_fcgi alias 
RUN service apache2 stop


# Install BIND DNS Server
RUN apt-get -y install bind9 dnsutils haveged
# deactivate ipv6
RUN sed -i 's/-u bind/-u bind -4/g' /etc/default/named
RUN service haveged start
RUN service named stop


# Install Webalizer and AWStats; vlogger is provided by the ISPConfig source tree below.
RUN apt-get -y install webalizer awstats geoip-database libclass-dbi-mysql-perl
ADD etc/cron.d/awstats /etc/cron.d/

# Install Jailkit and upstream Courier build dependencies
RUN apt-get -y install build-essential autoconf automake libtool flex bison debhelper devscripts autoconf-archive pkgconf libltdl-dev libldap2-dev libmariadb-dev libmariadb-dev-compat zlib1g-dev libsqlite3-dev libpq-dev libgdbm-dev libpam0g-dev libidn2-dev sysconftool expect libgnutls28-dev gnutls-bin libpcre2-dev libgcrypt20-dev systemd locales binutils python3 jailkit
RUN printf 'en_US ISO-8859-1\nen_US.UTF-8 UTF-8\n' >> /etc/locale.gen && locale-gen
ENV LANG=en_US.UTF-8

# Build Noble-compatible Courier packages from the maintained upstream release tarballs.
# Ubuntu Noble no longer publishes courier-base, courier-imap, courier-pop, or maildrop.
RUN set -eu; \
    build_dir=/tmp/courier-build; \
    mkdir -p "$build_dir/sources" "$build_dir/unicode" "$build_dir/authlib" "$build_dir/imap" "$build_dir/maildrop"; \
    cd "$build_dir/sources"; \
    wget -q -O courier-unicode-2.6.0.tar.bz2 https://sourceforge.net/projects/courier/files/courier-unicode/2.6.0/courier-unicode-2.6.0.tar.bz2/download; \
    wget -q -O courier-authlib-0.73.2.tar.bz2 https://downloads.sourceforge.net/project/courier/authlib/0.73.2/courier-authlib-0.73.2.tar.bz2; \
    wget -q -O courier-imap-6.0.7.tar.bz2 https://downloads.sourceforge.net/project/courier/imap/6.0.7/courier-imap-6.0.7.tar.bz2; \
    wget -q -O maildrop-4.0.1.tar.bz2 https://downloads.sourceforge.net/project/courier/maildrop/4.0.1/maildrop-4.0.1.tar.bz2; \
    echo '0aed2349c5b62de0d33ccf8c23527aae41daf95a03c8054c88de4faef8da8a08  courier-unicode-2.6.0.tar.bz2' | sha256sum -c -; \
    echo '8629a3af9a169fc64e9f8fd6aafd320ba42c2443db15bf97e9f6076fe6dda618  courier-authlib-0.73.2.tar.bz2' | sha256sum -c -; \
    echo '33827a707a14c155e858253e6aa82d7483d12c33bd09edbe4c3dd520dd13fd7f  courier-imap-6.0.7.tar.bz2' | sha256sum -c -; \
    echo 'f12c8f7b0c7f9474bac37b136b8def9287a9b3419da5cc2e47d9ffd05297e22f  maildrop-4.0.1.tar.bz2' | sha256sum -c -; \
    cp "$build_dir/sources/courier-unicode-2.6.0.tar.bz2" "$build_dir/unicode/"; \
    cd "$build_dir/unicode" && tar -xjf courier-unicode-2.6.0.tar.bz2 && cd courier-unicode-2.6.0 && ./courier-debuild -us -uc && apt-get install -y ./deb/*.deb; \
    cp "$build_dir/sources/courier-authlib-0.73.2.tar.bz2" "$build_dir/authlib/"; \
    cd "$build_dir/authlib" && tar -xjf courier-authlib-0.73.2.tar.bz2 && cd courier-authlib-0.73.2 && ./courier-debuild -us -uc; \
    apt-get purge -y courier-authdaemon courier-authlib courier-authlib-userdb courier-authlib-mysql; \
    apt-get install -y "$build_dir/authlib/courier-authlib-0.73.2/deb"/*.deb; \
    cp "$build_dir/sources/courier-imap-6.0.7.tar.bz2" "$build_dir/imap/"; \
    cd "$build_dir/imap" && tar -xjf courier-imap-6.0.7.tar.bz2 && cd courier-imap-6.0.7 && ./courier-debuild -us -uc && apt-get install -y ./deb/*.deb; \
    cp "$build_dir/sources/maildrop-4.0.1.tar.bz2" "$build_dir/maildrop/"; \
    cd "$build_dir/maildrop" && tar -xjf maildrop-4.0.1.tar.bz2 && cd maildrop-4.0.1 && ./courier-debuild -us -uc && apt-get install -y ./deb/*.deb; \
    ln -sf /usr/libexec/courier-authlib/courier-authlib.sysvinit /etc/init.d/courier-authdaemon; \
    ln -sf /usr/lib/courier-imap/share/courier-imap.sysvinit /etc/init.d/courier-imap; \
    ln -sf /usr/lib/courier-imap/share/courier-imap.sysvinit /etc/init.d/courier-imap-ssl; \
    ldconfig; \
    rm -rf "$build_dir"

# Keep Courier configuration in ISPConfig3's /etc/courier directory.
# The upstream build uses /usr/lib/courier-imap/etc, so retain that runtime path as a symlink.
RUN set -eu; \
    install -d -m 0755 /etc/courier; \
    mv /usr/lib/courier-imap/etc/* /etc/courier/; \
    rmdir /usr/lib/courier-imap/etc; \
    ln -s /etc/courier /usr/lib/courier-imap/etc; \
    install -m 0600 /usr/lib/courier-imap/share/imapd.pem /etc/courier/imapd.pem; \
    install -m 0600 /usr/lib/courier-imap/share/pop3d.pem /etc/courier/pop3d.pem; \
    install -m 0644 /usr/lib/courier-imap/share/dhparams.pem /etc/courier/dhparams.pem; \
    sed -i 's#^TLS_CERTFILE=.*#TLS_CERTFILE=/etc/courier/imapd.pem#; s#^TLS_DHPARAMS=.*#TLS_DHPARAMS=/etc/courier/dhparams.pem#' /etc/courier/imapd-ssl; \
    sed -i 's#^TLS_CERTFILE=.*#TLS_CERTFILE=/etc/courier/pop3d.pem#; s#^TLS_DHPARAMS=.*#TLS_DHPARAMS=/etc/courier/dhparams.pem#' /etc/courier/pop3d-ssl; \
    cp -p /etc/authlib/authdaemonrc /etc/courier/authdaemonrc; \
    cp -p /etc/authlib/authmysqlrc /etc/courier/authmysqlrc; \
    sed -i 's/^authmodulelist=.*/authmodulelist="authmysql"/; s/^authmodulelistorig=.*/authmodulelistorig="authmysql"/' /etc/courier/authdaemonrc; \
    grep -Fqx 'authmodulelist="authmysql"' /etc/courier/authdaemonrc; \
    grep -Fqx 'authmodulelistorig="authmysql"' /etc/courier/authdaemonrc; \
    ln -sfn /etc/courier/authdaemonrc /etc/authlib/authdaemonrc; \
    ln -sfn /etc/courier/authmysqlrc /etc/authlib/authmysqlrc

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
# Courier's SSL init alias starts the same all-listener service; keep only one Supervisor launcher.
RUN python3 -c 'from pathlib import Path; import re; p=Path("/etc/supervisor/supervisord.conf"); s=p.read_text(); s,n=re.subn(r"(?ms)^\[program:courier-imap-ssl\]\n.*?(?=^\[|\Z)", "", s); assert n == 1, "duplicate Courier SSL Supervisor section not found"; p.write_text(s)'
ADD ./etc/rsyslog/rsyslog.conf /etc/rsyslog.conf
ADD ./etc/cron.daily/sql_backup.sh /etc/cron.daily/sql_backup.sh

# Install ISPConfig 3
RUN git clone --branch $TAG_SYN --depth 1 https://github.com/AVENTER-UG/ispconfig3.git /tmp/ispconfig3_install
# Containers do not have CAP_LINUX_IMMUTABLE; skip ISPConfig's chattr hardening there.
RUN python3 -c 'from pathlib import Path; p=Path("/tmp/ispconfig3_install/install/lib/installer_base.lib.php"); s=p.read_text(); marker="\tpublic function set_immutable($path, $enable = true) {\n"; assert s.count(marker) == 1, "set_immutable marker changed"; p.write_text(s.replace(marker, marker + "\t\tif(is_file(\"/.dockerenv\")) return;\n", 1))'
#COPY ispconfig3 /tmp/ispconfig3_install
RUN install -m 0755 /tmp/ispconfig3_install/server/scripts/vlogger /usr/sbin/vlogger
RUN mkdir -p /tmp/ispconfig3_install/server/conf-custom/install && \
    printf '%s\n' \
        'smtpd_client_restrictions = check_client_access proxy:mysql:/etc/postfix/mysql-virtual_client.cf, permit_inet_interfaces, permit_mynetworks, permit_sasl_authenticated, reject_rbl_client zen.spamhaus.org, reject_rbl_client b.barracudacentral.org, reject_unauth_pipelining ,reject_unknown_client_hostname, check_client_access hash:/etc/letsencrypt/client_checks, permit' \
        'inet_protocols = ipv4' \
        'content_filter = amavis:[127.0.0.1]:10024' \
        'smtpd_reject_unlisted_sender = yes' \
        'maildrop_destination_recipient_limit = 1' \
		'message_size_limit = 52428800' \
        > /tmp/ispconfig3_install/server/conf-custom/install/postfix_custom.conf.master

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

## FIX: Postgrey listening interface
ADD ./etc/default/postgrey /etc/default/postgrey
ADD ./etc/default/saslauthd /etc/default/saslauthd

CMD ["/bin/bash", "/start.sh"]
