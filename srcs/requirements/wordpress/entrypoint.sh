#!/bin/sh
set -e

DB_PASSWORD=$(cat ${WORDPRESS_DB_PASSWORD_FILE})
WP_URL="https://${DOMAIN_NAME}"

echo "Waiting for MariaDB..."
while ! nc -z db 3306; do
    sleep 1
done

if [ ! -f /var/www/html/wp-settings.php ]; then
    mkdir -p /var/www/html
    cp -a /usr/src/wordpress/. /var/www/html/
fi

if [ ! -f /var/www/html/wp-config.php ]; then
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

    sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/" /var/www/html/wp-config.php
    sed -i "s/username_here/${WORDPRESS_DB_USER}/" /var/www/html/wp-config.php
    sed -i "s/password_here/${DB_PASSWORD}/" /var/www/html/wp-config.php
    sed -i "s/localhost/db/" /var/www/html/wp-config.php
fi

sed -i "/define( *'WP_HOME'/d" /var/www/html/wp-config.php
sed -i "/define( *'WP_SITEURL'/d" /var/www/html/wp-config.php
sed -i "/define( *'WP_REDIS_HOST'/d" /var/www/html/wp-config.php
sed -i "/define( *'WP_REDIS_PORT'/d" /var/www/html/wp-config.php
sed -i "/\/\* That's all, stop editing! Happy publishing. \*\//i define('WP_HOME', '${WP_URL}');" /var/www/html/wp-config.php
sed -i "/\/\* That's all, stop editing! Happy publishing. \*\//i define('WP_SITEURL', '${WP_URL}');" /var/www/html/wp-config.php
sed -i "/\/\* That's all, stop editing! Happy publishing. \*\//i define('WP_REDIS_HOST', 'bonus');" /var/www/html/wp-config.php
sed -i "/\/\* That's all, stop editing! Happy publishing. \*\//i define('WP_REDIS_PORT', 6379);" /var/www/html/wp-config.php

php-fpm8.2 -F
