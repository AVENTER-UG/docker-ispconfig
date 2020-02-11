# ISPConfig3 in a docker container

This docker image include a whole ISPConfig3 software stack. For details, I'm sorry have a look in the Dockerfile. Later I will write down all installed packages.

## How to use it

First, have a look at the following docker-compose file to get an idea.

```yaml
version: '3'

services:
  master:
    image: mariadb
    command: --max_allowed_packet=32505856
    restart: always
    volumes:
      - /data/db:/var/lib/mysql
    networks:
      - default
    hostname: master.weave.local
    environment:
      MYSQL_ROOT_PASSWORD: <PASSWORD>

  server1:
    image: avhost/ispconfig:latest
    ports:
      - "443:443"
      - "80:80"
    volumes: ["/data/amavis:/var/lib/amavis","/data/etc/amavis:/etc/amavis", "/data/letsencrypt:/etc/letsencrypt", "/data/etc/apache2/sites-available:/etc/apache2/sites-available", "/data/etc/apache2/sites-enabled:/etc/apache2/sites-enabled", "/data/www:/var/www/", "/data/backup:/var/backup/", "/data/usr:/usr/local/ispconfig", "/data/etc/cron.d:/etc/cron.d", "/data/kis/bind:/etc/bind"]
    restart: always
    depends_on:
      - master
    networks:
      - default
    hostname: server1.weave.local
    cap_add:
      - NET_ADMIN
      - NET_RAW
    environment:
      isp_mysql_hostname: "master.weave.local"
      isp_mysql_root_password: "<PASSWORD>"
      isp_mysql_ispconfig_password: "<PASSWORD>"
      isp_admin_password: "<PASSWORD>"
      isp_mysql_master_root_password: "<PASSWORD>"
      isp_mysql_master_hostname: "master"
      isp_enable_mail: "n"
      isp_enable_jailkit: "n"
      isp_enable_ftp: "n"
      isp_enable_dns: "n"
      isp_enable_apache: "y"
      isp_enable_nginx: "y"
      isp_enable_firewall: "y"
      isp_enable_webinterface: "n"
      isp_enable_multiserver: "y"
      isp_hostname: "server1"
      isp_use_ssl: "y"

networks:
  default:
    external:
      name: weave
```

Next, some words to say. If you will deploy a docker container with this image for the first time, it will not work if you persist already all the data (like above). First, just mount /var/backup inside of the container, start the container and then copy all the needed files/directories ONE TIME into the backup directory. Then shutdown the container, and persist the data like above with all the files you copied into the backup directory. Thats just a one time job. :-) Why you have to do it! As example, bind, amavis, postfix, all these packages have default files. If you persist from the beginging, the default files will not be there and the services will crash.

## Persist Data

There are some directories and files its easier if you don't persist them. As example:

- /etc/passwd
- /etc/shadow
- /etc/group
- /var/log/ispconfig

Specialy the system authentication files makes only problems if you try to persist them. Docker cannot handle a group/useradd on mounted auth files. To recreate the web/client users from ispconfig, you have to login into the webinterface, go to "Configuration", there on "resync" and then resync the "Websites" on the container you restarted. Thats it!

## The idea behind

The idea behind this images is the flexibility to move the whole ISPConfig Container, with the data, with the config, to a other server if you have to update or migrate the host system. Use this container as the "Real Server", and the Server where its running, just as a host system.

## Multiuser Environment

Yes its working! We are using it with weave.works and docker-compose. At the host system is dnsmasq to seperate the weave dns resolution from the external one and the one inside of the container.