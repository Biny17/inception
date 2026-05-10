*This project has been created as part of the 42 curriculum by tgallet.*

# Inception

## Description

Inception is a system administration project from the 42 School curriculum. The goal is to design and deploy a small but complete web-hosting infrastructure entirely inside Docker containers, without using any pre-built images from Docker Hub (except as base OS layers).

The stack runs three custom-built services:

- **Nginx** — HTTPS-only reverse proxy (TLSv1.3, self-signed certificate) that serves static files and forwards PHP requests.
- **WordPress + PHP-FPM** — Application server that renders the WordPress site and exposes the admin panel.
- **MariaDB** — Relational database that stores all WordPress content.

All services are isolated on a private Docker bridge network and communicate only with each other. The only port exposed to the host is **443**.

### Docker and source files

Every image is built from a `Dockerfile` located under `srcs/requirements/<service>/`. Each `Dockerfile` starts from `debian:bookworm` and installs only the packages needed for that service. No pre-built application images are used.

Service configuration files (`nginx.conf`, `entrypoint.sh`, `init.sh`) are copied into the images at build time.

Secrets (passwords, TLS keys) are injected at runtime via Docker secrets — they never appear in environment variables or image layers.

### Design choices

#### Virtual Machines vs Docker

A VM emulates an entire computer, including a full guest OS kernel, making it heavyweight (gigabytes of disk, seconds to boot). Docker containers share the host kernel; only the application and its dependencies are packaged. This project uses Docker because the goal is to learn container orchestration, and containers are far faster to iterate on than full VMs. VMs are still the right choice when hard isolation or a different kernel is required.

#### Secrets vs Environment Variables

Environment variables are convenient but visible to any process in the container and can leak through logs or inspection (`docker inspect`). Docker secrets mount credential files at `/run/secrets/` inside the container, readable only by the process that needs them, and they are never stored in the image. This project passes all passwords through Docker secrets, not environment variables.

#### Docker Network vs Host Network

With `network_mode: host`, a container shares the host's network stack — useful for performance, but it removes all network isolation and can expose services unintentionally. This project uses a custom bridge network (`agruet`) so that services can reach each other by name (`db`, `wordpress`, `nginx`) while remaining invisible to the outside world. Only the Nginx container maps a port (`443`) to the host.

#### Docker Volumes vs Bind Mounts

Bind mounts link a host directory directly into a container — easy for development but tied to the host's file-system layout. Named volumes are managed by Docker, portable, and survive container removal. This project uses two named volumes:

- `db_data` — MariaDB data directory, persists the database across restarts.
- `wordpress_files` — WordPress web root, shared between the WordPress and Nginx containers so Nginx can serve static assets directly.

---

## Instructions

### Prerequisites

- Docker and Docker Compose (v2)
- `make`
- `openssl` (used by the Makefile to generate secrets)
- `sudo` rights (needed once to add the domain to `/etc/hosts`)

### Installation and first run

```bash
# Clone the repository
git clone <repo-url> Inception
cd Inception

# Register the domain (requires sudo)
make add-host

# Build images and start the stack
make up
```

The first `make up` will:
1. Generate random passwords for MariaDB and the WordPress admin account.
2. Generate a self-signed TLS certificate valid for 365 days.
3. Build all three Docker images from source.
4. Start the containers in dependency order (MariaDB → WordPress → Nginx).

Once the stack is up, open `https://tgallet.42.fr` in your browser (accept the self-signed certificate warning).

### Makefile reference

| Target | Description |
|--------|-------------|
| `make up` | Build (if needed) and start all services |
| `make start` | Resume stopped containers without rebuilding |
| `make stop` | Pause containers (data preserved) |
| `make down` | Stop and remove containers |
| `make logs` | Stream live logs |
| `make ps` | Show container status |
| `make re` | Full teardown and rebuild |
| `make fclean` | Remove containers, volumes, images, and generated secrets |

### Configuration

Non-sensitive settings (domain, database name, admin username) are in `srcs/.env`. Copy `srcs/.env.example` and edit it before the first run if you need different values.

Passwords and TLS credentials are generated automatically under `secrets/` and are excluded from version control.

For full operational details (accessing the admin panel, reading credentials, troubleshooting) see [USER_DOC.md](USER_DOC.md).

---

## Resources

### Documentation

- [Docker Engine documentation](https://docs.docker.com/engine/)
- [Docker Compose file reference](https://docs.docker.com/compose/compose-file/)
- [Docker secrets documentation](https://docs.docker.com/engine/swarm/secrets/)
- [Nginx documentation](https://nginx.org/en/docs/)
- [WordPress CLI (WP-CLI)](https://wp-cli.org/)
- [MariaDB documentation](https://mariadb.com/kb/en/documentation/)
- [PHP-FPM configuration](https://www.php.net/manual/en/install.fpm.configuration.php)
- [Mozilla SSL Configuration Generator](https://ssl-config.mozilla.org/) — used to select TLSv1.3-only settings

### Use of AI

Claude (claude.ai / Claude Code CLI) was used during this project for the following tasks:

- **Generating boilerplate** — initial `Dockerfile` structures and `entrypoint.sh` / `init.sh` scripts were drafted with AI assistance and then reviewed and adjusted.
- **Debugging** — when services failed to start, AI helped interpret Docker logs and suggest fixes (e.g., PHP-FPM socket vs TCP listen address, MariaDB healthcheck command).
- **Writing documentation** — `README.md`, `USER_DOC.md`, and `DEV_DOC.md` were written with AI assistance based on the actual project structure.
- **Design questions** — AI was consulted to compare trade-offs (volumes vs bind mounts, secrets vs environment variables) and the explanations in this README are informed by those conversations.

All AI-generated content was verified against the official documentation and tested against the running stack.
