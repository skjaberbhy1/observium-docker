#!/bin/bash

set -e

echo "[INFO] Generating Observium config.php for cron container..."

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

?>
EOF

chmod 0644 /opt/observium/config.php

echo "[INFO] config.php generated successfully"

echo "[INFO] Starting cron daemon..."

exec "$@"