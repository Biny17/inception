# Inception — User Documentation

## Services Overview

The Inception stack runs three containerized services that together form a complete WordPress hosting infrastructure:

| Service | Technology | Role |
|---------|-----------|------|
| **Nginx** | Nginx (Debian Bookworm) | HTTPS entry point — terminates TLS and forwards PHP requests to WordPress |
| **WordPress** | PHP-FPM 8.2 + WP-CLI | Application server — renders pages and exposes the admin panel |
| **MariaDB** | MariaDB (Debian Bookworm) | Database — stores all WordPress content, users, and settings |

All three services communicate on a private Docker bridge network (`agruet`). Only port **443** (HTTPS) is exposed to the host.

---

## Starting and Stopping the Project

All operations are performed from the project root directory via `make`.

### First run

```bash
# 1. Add the domain to your /etc/hosts (requires sudo)
make add-host

# 2. Build images and start all services
make up
```

`make up` will automatically generate any missing secrets (TLS certificate, database passwords, WordPress admin password) before starting the stack.

### Day-to-day operations

| Command | Effect |
|---------|--------|
| `make up` | Build (if needed) and start all services in the foreground |
| `make start` | Resume previously stopped containers without rebuilding |
| `make stop` | Pause all running containers (data is preserved) |
| `make down` | Stop and remove containers (volumes and images are kept) |
| `make re` | Full rebuild from scratch (removes containers, volumes, and images) |
| `make logs` | Stream live logs from all services |
| `make ps` | Show the current status of each container |

---

## Accessing the Website and Administration Panel

> The domain is `tgallet.42.fr`. Make sure `make add-host` has been run at least once so your system resolves the domain to `127.0.0.1`.

| URL | What you get |
|-----|-------------|
| `https://tgallet.42.fr` | Public WordPress site |
| `https://tgallet.42.fr/wp-admin` | WordPress administration panel |

Because the TLS certificate is self-signed, your browser will show a security warning on first visit. Proceed past it (the connection is still encrypted).

### Logging in to the admin panel

1. Navigate to `https://tgallet.42.fr/wp-admin`.
2. Enter the admin username (default: `tgallet`).
3. The password is stored in `secrets/wp_password.txt` (see the Credentials section below).

---

## Credentials

All sensitive values are stored as files under the `secrets/` directory. They are generated automatically on first `make up`.

| File | Contains |
|------|---------|
| `secrets/wp_password.txt` | WordPress admin password |
| `secrets/db_password.txt` | MariaDB password for the WordPress database user |
| `secrets/db_root_password.txt` | MariaDB root password |
| `secrets/cert.pem` | Self-signed TLS certificate |
| `secrets/cert.key` | Private key for the TLS certificate |

To read a password:

```bash
cat secrets/wp_password.txt
```

Non-sensitive configuration (domain name, database name, WordPress admin username, admin email) lives in `srcs/.env`. Copy `srcs/.env.example` as a starting point if you need to customise these values.

> **Security note:** The `secrets/` directory is listed in `.gitignore` and must never be committed to the repository.

---

## Checking That Services Are Running

### Quick status check

```bash
make ps
```

All three containers (`nginx`, `wordpress`, `mariadb`) should show status `running`.

### Live logs

```bash
make logs
```

Press `Ctrl+C` to exit. Errors will appear in red in most terminals.

### Individual service logs

```bash
docker compose -f srcs/compose.yaml logs nginx
docker compose -f srcs/compose.yaml logs wordpress
docker compose -f srcs/compose.yaml logs mariadb
```

### Database connectivity test

```bash
docker compose -f srcs/compose.yaml exec db mariadb-admin ping -S /run/mysqld/mysqld.sock
```

Expected output: `mysqld is alive`

### End-to-end check

Open `https://tgallet.42.fr` in a browser. If the WordPress homepage loads, all three services are working correctly.
