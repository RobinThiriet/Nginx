SHELL := /bin/bash
ENV_FILE ?= .env.dev
COMPOSE_DEV = docker compose --env-file $(ENV_FILE) -f docker-compose.yml -f docker-compose.dev.yml
COMPOSE_PROD = docker compose --env-file $(ENV_FILE) -f docker-compose.yml -f docker-compose.prod.yml

.PHONY: help init init-dev init-prod up up-dev up-prod down down-dev down-prod restart logs ps validate test clean le-prod le-renew-prod le-install-cron-prod

help:
	@printf '%s\n' \
	'Commandes principales :' \
	'  make init-dev               Prepare l''environnement dev' \
	'  make up                     Lance la stack dev' \
	'  make up-prod                Lance la stack prod' \
	'  make down                   Arrete la stack dev' \
	'  make test                   Verifie la stack courante' \
	'' \
	'Commandes detaillees :' \
	'  make up-dev                 Lance le dev' \
	'  make init-prod              Prepare l''environnement prod' \
	'  make le-prod                Demande un certificat Let''s Encrypt' \
	'  make le-renew-prod          Renouvelle Let''s Encrypt' \
	'  make le-install-cron-prod   Installe le cron de renouvellement'

init:
	./scripts/generate-certs.sh
	./scripts/generate-htpasswd.sh

init-dev: ENV_FILE=.env.dev
init-dev:
	cp --update=none .env.dev.example .env.dev || true
	ENV_FILE=.env.dev ./scripts/generate-certs.sh
	ENV_FILE=.env.dev ./scripts/generate-htpasswd.sh

init-prod: ENV_FILE=.env.prod
init-prod:
	cp --update=none .env.prod.example .env.prod || true
	ENV_FILE=.env.prod ./scripts/generate-certs.sh
	ENV_FILE=.env.prod ./scripts/generate-htpasswd.sh

up:
	$(COMPOSE_DEV) up -d

up-dev: ENV_FILE=.env.dev
up-dev:
	$(COMPOSE_DEV) up -d

up-prod: ENV_FILE=.env.prod
up-prod:
	$(COMPOSE_PROD) up -d

down:
	$(COMPOSE_DEV) down

down-dev: ENV_FILE=.env.dev
down-dev:
	$(COMPOSE_DEV) down

down-prod: ENV_FILE=.env.prod
down-prod:
	$(COMPOSE_PROD) down

restart:
	$(COMPOSE_DEV) restart

logs:
	$(COMPOSE_DEV) logs -f --tail=200

ps:
	$(COMPOSE_DEV) ps

validate:
	$(COMPOSE_DEV) config >/tmp/nginx-lab-compose.rendered.yml
	$(COMPOSE_DEV) exec nginx nginx -t

test:
	./scripts/check-stack.sh

clean:
	$(COMPOSE_DEV) down -v --remove-orphans

le-prod:
	ENV_FILE=.env.prod ./scripts/request-letsencrypt.sh

le-renew-prod:
	ENV_FILE=.env.prod ./scripts/renew-letsencrypt.sh

le-install-cron-prod:
	./scripts/install-renew-cron.sh
