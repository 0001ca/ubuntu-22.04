FROM ubuntu:22.04
MAINTAINER Tyler Pohl <tylerapohl@gmail.com>
ENV REFRESHED_AT 2024-02-10

ENV DOCKER_USER_ID 501 
ENV DOCKER_USER_GID 20

ENV BOOT2DOCKER_ID 1000
ENV BOOT2DOCKER_GID 50

ENV PHPMYADMIN_VERSION=5.1.1
ENV SUPERVISOR_VERSION=4.2.2

ARG PHP_VERSION
ENV PHP_VERSION=$PHP_VERSION

# Tweaks to give Apache/PHP write permissions to the app
RUN usermod -u ${BOOT2DOCKER_ID} www-data && \
    usermod -G staff www-data && \
    useradd -r mysql && \
    usermod -G staff mysql && \
    groupmod -g $(($BOOT2DOCKER_GID + 10000)) $(getent group $BOOT2DOCKER_GID | cut -d: -f1) && \
    groupmod -g ${BOOT2DOCKER_GID} staff

# Install packages
ENV DEBIAN_FRONTEND noninteractive
RUN LC_ALL=C.UTF-8 apt-get update && \
  apt-get -y upgrade && \
  apt-get -y install apt-utils && \
  apt-get -y install python2 && \
#  apt-get -y install python2 postfix python3-setuptools wget git apache2 php-xdebug libapache2-mod-php mysql-server php-mysql pwgen php-apcu php-gd php-xml php-mbstring zip unzip php-zip curl php-curl && \
  apt-get -y install python2 postfix python3-setuptools wget git apache2 php${PHP_VERSION}-xdebug libapache2-mod-php${PHP_VERSION} mysql-server php${PHP_VERSION}-mysql pwgen php${PHP_VERSION}-apcu php${PHP_VERSION}-gd php${PHP_VERSION}-xml php${PHP_VERSION}-mbstring zip unzip php${PHP_VERSION}-zip curl php${PHP_VERSION}-curl && \
  apt-get -y autoremove && \
  apt-get -y clean && \
  echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Install supervisor 4
RUN curl -L https://pypi.io/packages/source/s/supervisor/supervisor-${SUPERVISOR_VERSION}.tar.gz | tar xvz && \
  cd supervisor-${SUPERVISOR_VERSION}/ && \
  python3 setup.py install

# Add image configuration and scripts
ADD supporting_files/start-apache2.sh /start-apache2.sh
ADD supporting_files/start-mysqld.sh /start-mysqld.sh
ADD supporting_files/start-syncthing.sh /start-syncthing.sh
ADD supporting_files/run.sh /run.sh
RUN chmod 755 /*.sh
ADD supporting_files/supervisord-apache2.conf /etc/supervisor/conf.d/supervisord-apache2.conf
ADD supporting_files/supervisord-mysqld.conf /etc/supervisor/conf.d/supervisord-mysqld.conf
ADD supporting_files/supervisord-syncthing.conf /etc/supervisor/conf.d/supervisord-syncthing.conf
ADD supporting_files/supervisord.conf /etc/supervisor/supervisord.conf

# Remove pre-installed database
RUN rm -rf /var/lib/mysql

# Add MySQL utils
ADD supporting_files/create_mysql_users.sh /create_mysql_users.sh

# Add phpmyadmin
RUN wget -O /tmp/phpmyadmin.tar.gz https://files.phpmyadmin.net/phpMyAdmin/${PHPMYADMIN_VERSION}/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages.tar.gz
RUN tar xfvz /tmp/phpmyadmin.tar.gz -C /var/www
RUN ln -s /var/www/phpMyAdmin-${PHPMYADMIN_VERSION}-all-languages /var/www/phpmyadmin
RUN mv /var/www/phpmyadmin/config.sample.inc.php /var/www/phpmyadmin/config.inc.php

# Set the localhost time
RUN cp /usr/share/zoneinfo/Canada/Pacific /etc/localtime

# Add pip2 and some libs
RUN wget -O /tmp/get-pip.py https://bootstrap.pypa.io/pip/2.7/get-pip.py
RUN python2 /tmp/get-pip.py
RUN pip2 install matplotlib pycomm mpld3 pandas

# Add pip3 and some libs
RUN apt-get -y install python3-pip
RUN pip3 install matplotlib sqlalchemy alpha_vantage pandas_datareader pandas bs4

# Add certbot for ssl encyption
RUN apt-get -y install certbot python3-certbot-apache syncthing

# Add composer
RUN php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');" && \
    php composer-setup.php && \
    php -r "unlink('composer-setup.php');" && \
    mv composer.phar /usr/local/bin/composer

ENV MYSQL_PASS:-$(pwgen -s 12 1)
# config to enable .htaccess
ADD supporting_files/apache_default /etc/apache2/sites-available/000-default.conf
RUN a2enmod rewrite

# Configure /app folder with sample app
RUN mkdir -p /app/html && rm -fr /var/www/html && ln -s /app/html /var/www/html
ADD app/ /app

#Environment variables to configure php
ENV PHP_UPLOAD_MAX_FILESIZE 10M
ENV PHP_POST_MAX_SIZE 10M

# Add volumes for the app and MySql
VOLUME  ["/var/lib/mysql", "/app" ]

EXPOSE 80 3306 8384
CMD ["/run.sh"]
