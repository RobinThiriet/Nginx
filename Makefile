SHELL := /bin/bash

.PHONY: init up down restart logs ps validate test clean

init:
	./scripts/generate-certs.sh
	./scripts/generate-htpasswd.sh

up:
	docker compose up -d

down:
	docker compose down

restart:
	docker compose restart

logs:
	docker compose logs -f --tail=200

ps:
	docker compose ps

validate:
	docker compose config >/tmp/nginx-lab-compose.rendered.yml
	docker compose exec nginx nginx -t

test:
	./scripts/check-stack.sh

clean:
	docker compose down -v --remove-orphans
