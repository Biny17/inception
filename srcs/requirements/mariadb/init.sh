#!/bin/bash
set -e

DB_PASSWORD=$(cat "$MARIADB_PASSWORD_FILE")
DB_ROOT_PASSWORD=$(cat "$MARIADB_ROOT_PASSWORD_FILE")

if [ ! -f /var/lib/mysql/.inception_initialized ]; then
	mysql_install_db --user=mysql --datadir=/var/lib/mysql > /dev/null

	mysqld_safe --skip-networking &
	MYSQL_PID=$!

	until mariadb-admin ping --silent; do
		sleep 1
	done

	mariadb -u root <<-SQL
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS \`${MARIADB_DATABASE}\`;
		CREATE USER IF NOT EXISTS '${MARIADB_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON \`${MARIADB_DATABASE}\`.* TO '${MARIADB_USER}'@'%';
		FLUSH PRIVILEGES;
	SQL

	mariadb-admin -u root -p"${DB_ROOT_PASSWORD}" shutdown
	wait $MYSQL_PID
	touch /var/lib/mysql/.inception_initialized
fi

echo "MariaDB initialized"

exec mysqld_safe --bind-address=0.0.0.0
