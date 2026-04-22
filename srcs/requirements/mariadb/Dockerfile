FROM debian:bookworm

RUN <<EOF
apt-get update
apt update
apt install -y mariadb-server mariadb-client galera-4
EOF

RUN mkdir -p /run/mysqld && chown mysql:mysql /run/mysqld

HEALTHCHECK --interval=5s --timeout=3s --start-period=10s \
  CMD mariadb-admin ping -h localhost || exit 1

EXPOSE 3306

COPY init.sh /usr/local/bin/init.sh
RUN chmod +x /usr/local/bin/init.sh

ENTRYPOINT ["init.sh"]

