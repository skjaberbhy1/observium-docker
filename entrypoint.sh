#!/bin/bash
set -euo pipefail

########################################
# Load environment safely
########################################
: "${DB_HOST:?DB_HOST not set}"
: "${DB_NAME:?DB_NAME not set}"
: "${DB_USER:?DB_USER not set}"
: "${DB_PASS:?DB_PASS not set}"

echo "[INFO] Starting Observium container..."

########################################
# Generate config.php (ENV driven)
########################################
cat <<EOF > /opt/observium/config.php
<?php

\$config['db_host'] = '${DB_HOST}';
\$config['db_name'] = '${DB_NAME}';
\$config['db_user'] = '${DB_USER}';
\$config['db_pass'] = '${DB_PASS}';

\$config['fping'] = "/usr/sbin/fping";

\$config['cache']['enable'] = TRUE;
\$config['cache']['driver'] = 'apcu';
\$config['login_remember_me'] = FALSE;

EOF

chown apache:apache /opt/observium/config.php

echo "[INFO] config.php generated"

########################################
# Wait for MariaDB
########################################
echo "[INFO] Waiting for MariaDB..."

until mariadb -h"$DB_HOST" \
              -u"$DB_USER" \
              -p"$DB_PASS" \
              -e "SELECT 1" >/dev/null 2>&1
do
  sleep 5
done

echo "[INFO] Database is ready"


########################################
# Initialize DB only if empty
########################################
if ! mariadb -h"$DB_HOST" -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" \
    -e "SHOW TABLES LIKE 'users';" | grep -q users; then

  echo "[INFO] Initializing database..."

  mariadb -h"$DB_HOST" \
          -u"$DB_USER" \
          -p"$DB_PASS" \
          "$DB_NAME" < /opt/observium/update/db_schema_mysql.sql

  echo "[INFO] Running Observium bootstrap discovery..."
  php /opt/observium/discovery.php -u 
  php /opt/observium/includes/pear_bootstrap.php
  echo "[INFO] Creating admin user..."
  php /opt/observium/adduser.php "$ADMIN_USER" "$ADMIN_PASS" 10
  


  touch /opt/observium/.db_initialized

else
  echo "[INFO] Database already initialized. Skipping..."
fi
########################################
# Runtime permissions
########################################
mkdir -p /run/php-fpm
chown -R apache:apache /run/php-fpm

echo "[INFO] Starting PHP-FPM..."
php-fpm -D



echo "[INFO] Starting Apache..."
exec /usr/sbin/httpd -D FOREGROUND