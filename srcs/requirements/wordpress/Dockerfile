FROM debian:bookworm

RUN <<EOF
apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    netcat-openbsd \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-gd \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    ssmtp \
    curl
rm -rf /var/lib/apt/lists/*
EOF

RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 0.0.0.0:9000|' /etc/php/8.2/fpm/pool.d/www.conf

RUN <<EOF
mkdir -p /usr/src/wordpress
curl -o /tmp/wordpress.tar.gz -fL "https://wordpress.org/latest.tar.gz" \
    && tar -xzf /tmp/wordpress.tar.gz -C /usr/src/wordpress --strip-components=1 \
    && rm /tmp/wordpress.tar.gz \
    && chown -R www-data:www-data /usr/src/wordpress
curl -o /usr/local/bin/wp -fL "https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar" \
    && chmod +x /usr/local/bin/wp
EOF

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

RUN mkdir -p /var/www/html
WORKDIR /var/www/html

EXPOSE 9000

ENTRYPOINT ["/entrypoint.sh"]
