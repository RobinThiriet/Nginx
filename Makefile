SHELL := /bin/bash
ENV_FILE ?= .env
COMPOSE_DEV = docker compose --env-file $(ENV_FILE) -f docker-compose.yml -f docker-compose.dev.yml
COMPOSE_PROD = docker compose --env-file $(ENV_FILE) -f docker-compose.yml -f docker-compose.prod.yml

.PHONY: init init-dev init-prod up up-dev up-prod down down-dev down-prod restart logs ps validate test clean backup-dev backup-prod

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

backup-dev:
	ENV_FILE=.env.dev ./scripts/backup-volumes.sh

backup-prod:
	ENV_FILE=.env.prod ./scripts/backup-volumes.sh
