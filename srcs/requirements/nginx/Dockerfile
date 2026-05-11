FROM debian:bookworm

RUN <<EOF
apt-get update
apt install -y curl gnupg2 ca-certificates lsb-release debian-archive-keyring
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
    | tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
https://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list
tee /etc/apt/preferences.d/99nginx <<'PREF'
Package: *
Pin: origin nginx.org
Pin: release o=nginx
Pin-Priority: 900
PREF
apt update
apt install -y nginx
EOF

COPY ./nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080

CMD ["nginx"]
