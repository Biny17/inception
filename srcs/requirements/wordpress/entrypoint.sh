#!/bin/sh

SQL_USER=$WORDPRESS_DB_USER
SQL_PASSWORD=$(cat $WORDPRESS_DB_PASSWORD_FILE)
WP_ADMIN=$WORDPRESS_ADMIN
WP_ADMIN_PASSWORD=$(cat $WORDPRESS_ADMIN_PASSWORD_FILE)

SQL_DATABASE=$WORDPRESS_DB_NAME

while ! nc -z $WORDPRESS_DB_HOST 3306; do
    sleep 1
done

if [ ! -f ./wp-config.php ]; then
    cp -a /usr/src/wordpress/. .

    wp config create \
        --dbname=$SQL_DATABASE \
        --dbuser=$SQL_USER \
        --dbpass=$SQL_PASSWORD \
        --dbhost=$WORDPRESS_DB_HOST \
        --allow-root

    wp core install \
        --url=$DOMAIN_NAME \
        --title="$WP_TITLE" \
        --admin_user=$WP_ADMIN \
        --admin_password=$WP_ADMIN_PASSWORD \
        --admin_email=$WP_ADMIN_EMAIL \
        --allow-root

    wp user create editor editor@example.com --role=editor --user_pass=editor42pass --allow-root

fi

chmod -R 755 /var/www/html

echo "Wordpress initialized"

exec php-fpm8.2 -F
