all: up

up: secrets secrets/db_password.txt secrets/db_root_password.txt secrets/cert.key secrets/cert.pem
	docker compose -f srcs/compose.yaml up

down:
	docker compose -f srcs/compose.yaml down

stop:
	docker compose -f srcs/compose.yaml stop

re: fclean up

fclean: clean
	docker compose -f srcs/compose.yaml down --volumes --rmi all --remove-orphans

clean:
	rm -rf secrets

secrets:
	mkdir -p secrets

secrets/db_password.txt: secrets
	openssl rand -base64 8 > secrets/db_password.txt

secrets/db_root_password.txt: secrets
	openssl rand -base64 8 > secrets/db_root_password.txt

secrets/cert.key: secrets
	openssl genrsa -out secrets/cert.key 4096

secrets/cert.pem: secrets secrets/cert.key
	openssl req -x509 -key secrets/cert.key -out secrets/cert.pem \
		-sha256 -days 365 -nodes \
		-subj "/CN=localhost"

.PHONY: up

