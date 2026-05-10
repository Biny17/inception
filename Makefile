DOMAIN = tgallet.42.fr
HOSTLINE = 127.0.0.1 $(DOMAIN)

all: up

up: secrets \
		secrets/db_password.txt \
		secrets/db_root_password.txt \
		secrets/cert.key \
		secrets/cert.pem \
		secrets/wp_password.txt \
		data_dirs
	docker compose -f srcs/compose.yaml up

start:
	docker compose -f srcs/compose.yaml start

down:
	docker compose -f srcs/compose.yaml down

stop:
	docker compose -f srcs/compose.yaml stop

logs:
	docker compose -f srcs/compose.yaml logs -f

ps:
	docker compose -f srcs/compose.yaml ps

build:
	docker compose -f srcs/compose.yaml build

re: fclean up

fclean: down clean
	docker compose -f srcs/compose.yaml down --volumes --rmi all --remove-orphans
	sudo rm -rf /home/$(USER)/data/wordpress
	sudo rm -rf /home/$(USER)/data/mariadb

clean:
	rm -rf secrets

secrets:
	mkdir -p secrets

secrets/db_password.txt: secrets
	openssl rand -base64 10 > $@

secrets/db_root_password.txt: secrets
	openssl rand -base64 10 > $@

secrets/cert.key: secrets
	openssl genrsa -out $@ 4096

secrets/cert.pem: secrets secrets/cert.key
	openssl req -x509 -key secrets/cert.key -out $@ \
		-sha256 -days 365 -nodes \
		-subj "/CN=localhost"

secrets/wp_password.txt: secrets
	openssl rand -base64 10 > $@

add-host:
	grep -qF "$(HOSTLINE)" /etc/hosts || echo "$(HOSTLINE)" | sudo tee -a /etc/hosts

data_dirs: /home/$(USER)/data/wordpress /home/$(USER)/data/mariadb

/home/$(USER)/data/wordpress:
	mkdir -p $@

/home/$(USER)/data/mariadb:
	mkdir -p $@

.PHONY: up start down stop logs ps build data_dirs re clean fclean

