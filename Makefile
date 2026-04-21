all: up

up: secrets secrets/db_password secrets/db_root_password secrets/cert.key secrets/cert.pem
	docker compose -f srcs/compose.yaml up

secrets:
	mkdir -p secrets

secrets/db_password: secrets
	openssl rand -base64 32 > secrets/db_password

secrets/db_root_password: secrets
	openssl rand -base64 32 > secrets/db_root_password

secrets/cert.key: secrets
	openssl genrsa -out secrets/cert.key 4096

secrets/cert.pem: secrets secrets/cert.key
	openssl req -x509 -key secrets/cert.key -out secrets/cert.pem \
		-sha256 -days 365 -nodes \
		-subj "/CN=localhost"

.PHONY: up 

