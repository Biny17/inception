FROM debian:bookworm

RUN <<EOF
apt-get update
apt update
apt install -y mariadb-server mariadb-client galera-4
EOF

EXPOSE 3306

CMD ["systemctl", "start", "mariadb"]