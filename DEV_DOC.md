# 🍓 Inception — Developer Documentation 🍓

> A fully containerized WordPress infrastructure built for the 42 School project.
> Three services, one network, zero compromises. 🍋

---

## 📋 Table of Contents

1. [🗺️ Project Overview](#️-project-overview)
2. [🍊 Architecture](#-architecture)
3. [🛠️ Prerequisites](#️-prerequisites)
4. [🚀 Quick Start](#-quick-start)
5. [📁 Project Structure](#-project-structure)
6. [🐳 Services Deep Dive](#-services-deep-dive)
   - [🍇 Nginx](#-nginx)
   - [🍈 WordPress (PHP-FPM)](#-wordpress-php-fpm)
   - [🍉 MariaDB](#-mariadb)
7. [🔐 Secrets Management](#-secrets-management)
8. [🌍 Environment Variables](#-environment-variables)
9. [🎛️ Makefile Targets](#️-makefile-targets)
10. [🍑 Customization Guide](#-customization-guide)
    - [Change Domain Name](#change-domain-name)
    - [Change WordPress Config](#change-wordpress-config)
    - [Change Database Config](#change-database-config)
    - [Add a New Service](#add-a-new-service)
    - [Customize Nginx](#customize-nginx)
    - [Tune PHP-FPM](#tune-php-fpm)
11. [🔑 SSL/TLS Certificates](#-ssltls-certificates)
12. [💾 Volumes & Data Persistence](#-volumes--data-persistence)
13. [🌐 Networking](#-networking)
14. [🩺 Health Checks](#-health-checks)
15. [🐛 Troubleshooting](#-troubleshooting)

---

## 🗺️ Project Overview

**Inception** is a Docker Compose project that deploys a production-like WordPress stack with:

| Component | Technology | Purpose |
|-----------|-----------|---------|
| 🍇 Web Server | Nginx (latest, Debian Bookworm) | Reverse proxy + SSL termination |
| 🍈 App Server | PHP-FPM 8.2 + WordPress | Dynamic content |
| 🍉 Database | MariaDB | Persistent data storage |

**Key design choices 🍋:**
- 🔒 **TLSv1.3 only** — no insecure HTTP
- 🔑 **Docker secrets** — passwords never in environment variables
- 🏥 **Health checks** — services wait for dependencies before starting
- 📦 **Named volumes** — data survives container restarts
- 🌐 **Custom bridge network** — services are isolated from the default Docker network

---

## 🍊 Architecture

```
                 ┌─────────────────────────────────────────┐
                 │            Docker Network: incept_net       │
                 │                                         │
  HTTPS:443      │   ┌──────────┐     FastCGI:9000         │
 ──────────────► │   │  Nginx   │ ──────────▼              │
                 │   └──────────┘     ┌───────────────┐    │
                 │        │           │  WordPress    │    │
                 │        │           │  (PHP-FPM)    │    │
                 │   /var/www/html    └───────┬───────┘    │
                 │   (shared vol.)            │            │
                 │                    MySQL:3306           │
                 │                    ┌──────▼──────┐      │
                 │                    │   MariaDB   │      │
                 │                    └─────────────┘      │
                 └─────────────────────────────────────────┘
```

**Data flow 🍓:**
1. Browser hits `https://<DOMAIN_NAME>`
2. Nginx terminates TLS and serves static files from the shared volume
3. PHP requests are proxied to WordPress via FastCGI on port 9000
4. WordPress queries MariaDB on port 3306

---

## 🛠️ Prerequisites

Make sure you have these installed 🍋:

```bash
docker --version      # Docker Engine 24+
docker compose version # Docker Compose v2+
make --version        # GNU Make
openssl version       # For self-signed cert generation
```

---

## 🚀 Quick Start

```bash
# 1. Clone the repository
git clone <repo-url> && cd Inception

# 2. Copy the env template and fill in your values
cp srcs/.env.example srcs/.env
$EDITOR srcs/.env

# 3. Build and start everything (secrets are auto-generated!)
make

# 4. Add the domain to your /etc/hosts (for local dev)
make add-host

# 5. Open in your browser https://localhost

```

> 🍊 **That's it!** The Makefile handles secret generation, image building, and container startup automatically.

---

## 📁 Project Structure

```
Inception/
├── 📄 Makefile                   ← Build automation (start here!)
├── 📄 dev_docs.md                ← You are here 🍓
│
├── 🔐 secrets/                   ← Auto-generated, gitignored
│   ├── cert.key                  ← RSA 4096-bit private key
│   ├── cert.pem                  ← Self-signed X.509 cert
│   ├── db_password.txt           ← MariaDB user password
│   ├── db_root_password.txt      ← MariaDB root password
│   └── wp_password.txt           ← WordPress admin password
│
└── 📁 srcs/
    ├── 📄 .env                   ← Your local config (gitignored)
    ├── 📄 .env.example           ← Template to copy
    ├── 📄 compose.yaml           ← Docker Compose orchestration
    │
    └── 📁 requirements/
        ├── 🍇 nginx/
        │   ├── Dockerfile
        │   └── nginx.conf
        ├── 🍈 wordpress/
        │   ├── Dockerfile
        │   └── entrypoint.sh
        └── 🍉 mariadb/
            ├── Dockerfile
            └── init.sh
```

---

## 🐳 Services Deep Dive

### 🍇 Nginx

**File:** `srcs/requirements/nginx/`

**Base image:** Debian Bookworm (custom, NOT the official `nginx` image — 42 rules!)

**What it does:**
- Installs Nginx from the official Nginx apt repository with GPG verification
- Serves static WordPress files from the shared `wordpress_files` volume
- Proxies all `.php` requests to `wordpress:9000` via FastCGI
- Terminates TLS using secrets-mounted certificates

**Key config (`nginx.conf`):**

```nginx
# TLSv1.3 only — modern and secure 🔒
ssl_protocols TLSv1.3;

# FastCGI proxy to WordPress
location ~ \.php$ {
    fastcgi_pass wordpress:9000;
    # ...
}

# WordPress pretty URLs
try_files $uri $uri/ /index.php?$args;
```

---

### 🍈 WordPress (PHP-FPM)

**File:** `srcs/requirements/wordpress/`

**Base image:** Debian Bookworm

**PHP version:** 8.2 with modules: `php8.2-fpm`, `php8.2-mysql`, `php8.2-gd`, `php8.2-curl`, `php8.2-mbstring`, `php8.2-xml`, `php8.2-zip`

**Tools included:** `wp-cli` (the `wp` command)

**What `entrypoint.sh` does on first boot 🍓:**
1. Reads database password from `/run/secrets/db_password`
2. Reads admin password from `/run/secrets/wp_password`
3. Waits until MariaDB is reachable on port 3306
4. Copies WordPress files from `/usr/src/wordpress` → `/var/www/html`
5. Generates `wp-config.php` from environment variables
6. Runs `wp core install` to create the site
7. Creates an additional `editor` user
8. Sets permissions (755) on `/var/www/html`
9. Starts `php-fpm8.2` in foreground

**Subsequent boots:** skips installation if `wp-config.php` already exists.

---

### 🍉 MariaDB

**File:** `srcs/requirements/mariadb/`

**Base image:** Debian Bookworm

**What `init.sh` does on first boot:**
1. Reads passwords from `/run/secrets/`
2. Checks for `.inception_initialized` marker
3. Creates the database, user, and grants privileges
4. Binds MariaDB to `0.0.0.0` so WordPress can connect
5. Writes the marker file and restarts with `mysqld_safe`

**Healthcheck:** runs `mariadb-admin ping` every 10 seconds (5s timeout, 5 retries, 30s start period).

---

## 🔐 Secrets Management

All sensitive values are handled via **Docker secrets** — they are mounted as files under `/run/secrets/` inside containers. **Passwords never appear in environment variables or image layers.** 🔑

| Secret file | Used by | Description |
|-------------|---------|-------------|
| `secrets/db_password.txt` | WordPress + MariaDB | MariaDB user password |
| `secrets/db_root_password.txt` | MariaDB | MariaDB root password |
| `secrets/wp_password.txt` | WordPress | WordPress admin password |
| `secrets/cert.pem` | Nginx | SSL certificate |
| `secrets/cert.key` | Nginx | SSL private key |

**Auto-generation 🍋:** The Makefile generates all secrets automatically if they don't exist:

```makefile
secrets/db_password.txt:
    openssl rand -base64 10 > $@

secrets/cert.key:
    openssl genrsa -out $@ 4096

secrets/cert.pem:
    openssl req -new -x509 -key secrets/cert.key -out $@ -days 365 \
        -subj "/CN=localhost"
```

> ⚠️ **Never commit the `secrets/` folder!**

---

## 🌍 Environment Variables

Copy `.env.example` to `.env` and set these values 🍊:

```bash
# Your site's domain name (used in Nginx + WordPress install)
DOMAIN_NAME=localhost          # or tgallet.42.fr for 42 eval

# MariaDB
MARIADB_DATABASE=wordpress     # Name of the database
MARIADB_USER=wpuser            # Non-root DB user
WORDPRESS_DB_HOST=mariadb           # Service name in Docker Compose
WORDPRESS_DB_NAME=wordpress    # Must match MARIADB_DATABASE

# WordPress
WP_TITLE=Inception             # Site title displayed in the browser tab
WORDPRESS_ADMIN=tgallet        # Admin username
WP_ADMIN_EMAIL=your@email.com  # Admin email
```

> 🍓 Don't commit your .env ! :stuck_out_tongue_winking_eye:

---

## 🎛️ Makefile Targets

| Target | Command | Description |
|--------|---------|-------------|
| `all` | `make` | Alias for `up` |
| `up` | `make up` | 🚀 Build images and start all containers |
| `start` | `make start` | ▶️ Resume containers stopped with `make stop` |
| `down` | `make down` | 🛑 Stop and remove containers |
| `stop` | `make stop` | ⏸️ Stop containers (keep data, resumable) |
| `logs` | `make logs` | 📜 Tail all container logs (follow mode) |
| `ps` | `make ps` | 📊 Show container status |
| `build` | `make build` | 🔨 Build images without starting containers |
| `re` | `make re` | 🔄 Full clean rebuild |
| `fclean` | `make fclean` | 🗑️ Remove containers, volumes, images, secrets |
| `clean` | `make clean` | 🧹 Remove secrets directory only |
| `add-host` | `make add-host` | 🌐 Add domain to `/etc/hosts` |

---

## 🍑 Customization Guide

### Change Domain Name

1. Edit `srcs/.env`:
   ```bash
   DOMAIN_NAME=mysite.42.fr
   ```

2. Update the Makefile `DOMAIN` variable (for `add-host`):
   ```makefile
   DOMAIN = mysite.42.fr
   ```

3. Regenerate the SSL certificate for the new CN:
   ```bash
   rm secrets/cert.key secrets/cert.pem
   make secrets/cert.key secrets/cert.pem
   ```

4. Rebuild and restart:
   ```bash
   make re
   ```

---

### Change WordPress Config

**WordPress title, admin username, or email** → edit `srcs/.env`:
```bash
WP_TITLE=My Awesome Blog 🍓
WORDPRESS_ADMIN=myusername
WP_ADMIN_EMAIL=me@example.com
```

> ⚠️ These only take effect on first boot (when WordPress is installed). To re-apply, run `make fclean && make`.

**WordPress admin password** → delete and regenerate the secret:
```bash
rm secrets/wp_password.txt
make secrets/wp_password.txt
make re
```

**Add a WordPress plugin or theme at build time** → edit `srcs/requirements/wordpress/entrypoint.sh`:
```bash
# Add after the wp core install line:
wp plugin install woocommerce --activate --allow-root
wp theme install astra --activate --allow-root
```

---

### Change Database Config

**Database name or user** → edit `srcs/.env`:
```bash
MARIADB_DATABASE=mydb
MARIADB_USER=mydbuser
WORDPRESS_DB_NAME=mydb
```

> 🍉 If you change these after first boot, you must `make fclean && make` to reinitialize the database volume.

**Database passwords** → delete and regenerate:
```bash
rm secrets/db_password.txt secrets/db_root_password.txt
make secrets/db_password.txt secrets/db_root_password.txt
make re
```

---

### Add a New Service

1. Create a new folder under `srcs/requirements/`:
   ```
   srcs/requirements/redis/
   ├── Dockerfile
   └── redis.conf
   ```

2. Write your `Dockerfile` using **Debian Bookworm** as the base (42 rule — no official service images!):
   ```dockerfile
   FROM debian:bookworm

   RUN apt-get update && apt-get install -y redis-server && rm -rf /var/lib/apt/lists/*

   COPY redis.conf /etc/redis/redis.conf

   EXPOSE 6379
   CMD ["redis-server", "/etc/redis/redis.conf"]
   ```

3. Add the service to `srcs/compose.yaml`:
   ```yaml
   redis:
     build: ./requirements/redis
     networks:
       - incept_net
     restart: unless-stopped
   ```

4. Add the network to `networks` if not already present.

5. Connect it from WordPress by adding the host to your `srcs/.env` and updating `entrypoint.sh`.

---

### Customize Nginx

Edit `srcs/requirements/nginx/nginx.conf`. Common tweaks 🍇:

**Increase upload limit** (for large media):
```nginx
client_max_body_size 64m;
```

**Add gzip compression:**
```nginx
gzip on;
gzip_types text/css application/javascript application/json image/svg+xml;
gzip_min_length 1024;
```

**Add a custom header:**
```nginx
add_header X-Frame-Options "SAMEORIGIN";
add_header X-Content-Type-Options "nosniff";
```

**Serve a custom error page:**
```nginx
error_page 404 /404.html;
location = /404.html {
    root /var/www/html;
    internal;
}
```

After any nginx.conf change, rebuild the image:
```bash
make re
# or just restart nginx if you didn't change the Dockerfile:
docker compose -f srcs/compose.yaml restart nginx
```

---

### Tune PHP-FPM

Edit `srcs/requirements/wordpress/Dockerfile` to add a custom PHP-FPM pool config 🍈:

```dockerfile
# Copy your custom pool config
COPY www.conf /etc/php/8.2/fpm/pool.d/www.conf
```

**Example `www.conf` tweaks:**
```ini
; Increase workers for higher traffic
pm = dynamic
pm.max_children = 20
pm.start_servers = 5
pm.min_spare_servers = 2
pm.max_spare_servers = 8

; Increase upload and memory limits
php_admin_value[upload_max_filesize] = 64M
php_admin_value[memory_limit] = 256M
php_admin_value[post_max_size] = 64M
```

---

## 🔑 SSL/TLS Certificates

By default, the Makefile generates a **self-signed certificate** (your browser will warn you). For local dev, just click "Accept the risk."

**For 42 evaluation** — the subject is set to `localhost` by default. Change it to match your domain:

```makefile
secrets/cert.pem: secrets/cert.key
	openssl req -new -x509 -key $< -out $@ -days 365 \
		-subj "/C=FR/ST=IDF/L=Paris/O=42/CN=$(DOMAIN)"
```

**To use a real certificate (Let's Encrypt, etc.):**
1. Obtain `fullchain.pem` and `privkey.pem` from your CA
2. Copy them to `secrets/cert.pem` and `secrets/cert.key`
3. Run `make up` (no rebuild needed — secrets are mounted at runtime)

---

## 💾 Volumes & Data Persistence

| Volume | Mount point | Service | Purpose |
|--------|-------------|---------|---------|
| `db_data` | `/var/lib/mysql` | MariaDB | Database files |
| `wordpress_files` | `/var/www/html` | WordPress + Nginx | WordPress installation |

**Full wipe (⚠️ destroys all data):**
```bash
make fclean
```

---

## 🌐 Networking

All services share the custom bridge network `incept_net`. Services communicate by their **Compose service name** (Docker's built-in DNS):

| From | To | Address |
|------|----|---------|
| Nginx | WordPress | `wordpress:9000` |
| WordPress | MariaDB | `mariadb:3306` |

Only Nginx exposes a port to the host (`443:443`). WordPress and MariaDB are not reachable from outside the Docker network.

**To expose MariaDB to the host temporarily** (debugging only!):
```yaml
# In compose.yaml, under db:
ports:
  - "3306:3306"
```

> ⚠️ Remove this before production/evaluation!

---

## 🩺 Health Checks

**MariaDB** has a built-in healthcheck:
```yaml
healthcheck:
  test: ["CMD", "mariadb-admin", "ping", "-h", "localhost"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s
```

**WordPress** waits for MariaDB at the application level (polling port 3306 in `entrypoint.sh`).

**Nginx** depends on both and starts once WordPress has started.

Check health status:
```bash
docker compose -f srcs/compose.yaml ps
# Look for (healthy) in the STATUS column
```

---

## 🐛 Troubleshooting

**🍊 Containers keep restarting?**
```bash
docker compose -f srcs/compose.yaml logs <service>
```

**🍋 WordPress can't connect to the database?**
- Check MariaDB is healthy: `docker compose -f srcs/compose.yaml ps`
- Verify `MARIADB_USER` in `.env` matches what `init.sh` creates
- Make sure `WORDPRESS_DB_HOST=mariadb` (the service name, not an IP)

**🍇 Nginx 502 Bad Gateway?**
- WordPress container may still be installing — wait ~30 seconds
- Check WordPress logs: `docker compose -f srcs/compose.yaml logs wordpress`

**🍈 SSL certificate warning in browser?**
- Expected for self-signed certs. Click "Advanced" → "Accept the risk"
- Or import `secrets/cert.pem` into your browser's trusted certificates

**🍉 Changes to .env not applying?**
- For WordPress/MariaDB first-boot config: `make fclean && make`
- For Nginx: `docker compose -f srcs/compose.yaml restart nginx`

**🔑 Forgot the WordPress admin password?**
```bash
cat secrets/wp_password.txt
```

**🍓 Want a fresh start?**
```bash
make fclean && make
```