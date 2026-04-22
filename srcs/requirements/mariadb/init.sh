#!/bin/bash
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First run: Initializing MariaDB..."
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql
fi

exec mariadbd --user=mysql --bind-address=0.0.0.0
