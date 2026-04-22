FROM debian:bookworm

RUN <<EOF
apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    php8.2-fpm \
    php8.2-mysql \
    php8.2-gd \
    php8.2-curl \
    php8.2-mbstring \
    php8.2-xml \
    php8.2-zip \
    curl
rm -rf /var/lib/apt/lists/*
EOF

RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 0.0.0.0:9000|' /etc/php/8.2/fpm/pool.d/www.conf

RUN <<EOF
mkdir -p /var/www/html
curl -o /tmp/wordpress.tar.gz -fL "https://wordpress.org/latest.tar.gz" \
    && tar -xzf /tmp/wordpress.tar.gz -C /var/www/html --strip-components=1 \
    && rm /tmp/wordpress.tar.gz \
    && chown -R www-data:www-data /var/www/html
EOF

WORKDIR /var/www/html

EXPOSE 9000

CMD ["/usr/sbin/php-fpm8.2", "-F"]