FROM rockylinux:9

#############################################
# Minimal install (optimized)
#############################################
RUN dnf -y install epel-release && \
    dnf -y install \
        httpd \
        php \
        php-cli \
        php-fpm \
        php-mysqlnd \
        php-snmp \
        php-gd \
        php-mbstring \
        php-xml \
        php-zip \
        php-process \
        php-opcache \
        php-pecl-apcu \
        php-pear \
        rrdtool \
        net-snmp \
        net-snmp-utils \
        fping \
        iputils \
        cronie \
        mariadb \
        mariadb-common \
        mariadb-connector-c \
        python3 \
        python3-pip && \
    pip3 install PyMySQL && \
    pear install Net_IPv4 || true && \
    dnf clean all && \
    rm -rf /var/cache/dnf


#############################################
# Apache config
#############################################
RUN sed -i 's/#LoadModule rewrite_module/LoadModule rewrite_module/' \
    /etc/httpd/conf.modules.d/00-base.conf && \
    echo "ServerName localhost" >> /etc/httpd/conf/httpd.conf

RUN sed -i 's#DocumentRoot "/var/www/html"#DocumentRoot "/opt/observium/html"#g' \
    /etc/httpd/conf/httpd.conf

RUN echo '<Directory "/opt/observium/html">' >> /etc/httpd/conf/httpd.conf && \
    echo '    AllowOverride All' >> /etc/httpd/conf/httpd.conf && \
    echo '    Require all granted' >> /etc/httpd/conf/httpd.conf && \
    echo '</Directory>' >> /etc/httpd/conf/httpd.conf

#############################################
# PHP config
#############################################
RUN echo "date.timezone = Asia/Dhaka" > /etc/php.d/custom.ini && \
    echo "memory_limit = 512M" >> /etc/php.d/custom.ini && \
    echo "upload_max_filesize = 50M" >> /etc/php.d/custom.ini && \
    echo "post_max_size = 50M" >> /etc/php.d/custom.ini && \
    echo "max_execution_time = 300" >> /etc/php.d/custom.ini && \
    echo "opcache.enable=1" > /etc/php.d/opcache.ini


#############################################
# App
#############################################
COPY . /opt/observium

WORKDIR /opt/observium

RUN mkdir -p rrd logs && \
    chown -R apache:apache /opt/observium

RUN echo "include_path=.:/usr/share/pear:/opt/observium/libs/pear" > /etc/php.d/pear.ini
RUN echo "<?php require_once '/opt/observium/libs/pear/Net/IPv4.php';" > /opt/observium/includes/pear_bootstrap.php
#############################################
# Entrypoint
#############################################
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]