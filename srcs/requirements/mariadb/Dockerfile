FROM debian:bookworm

RUN <<EOF
apt-get update
apt update
apt install -y mariadb-server mariadb-client galera-4
EOF

RUN mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

COPY my.cnf /etc/mysql/conf.d/my.cnf

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s \
  CMD mariadb-admin ping -h 127.0.0.1 -P 3306 --silent || exit 1

EXPOSE 3306

COPY init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["init.sh"]

