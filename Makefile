SHELL := /bin/bash
COMPOSE_DEV := docker compose -f docker-compose.yml -f docker-compose.dev.yml
COMPOSE_PROD := docker compose -f docker-compose.yml -f docker-compose.prod.yml

.PHONY: init up up-dev up-prod down down-dev down-prod restart logs ps validate test clean

init:
	./scripts/generate-certs.sh
	./scripts/generate-htpasswd.sh

up:
	$(COMPOSE_DEV) up -d

up-dev:
	$(COMPOSE_DEV) up -d

up-prod:
	$(COMPOSE_PROD) up -d

down:
	$(COMPOSE_DEV) down

down-dev:
	$(COMPOSE_DEV) down

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
