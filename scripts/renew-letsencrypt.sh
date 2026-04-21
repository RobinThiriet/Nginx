#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/${ENV_FILE:-.env.prod}"
COMPOSE_CMD=(docker compose --env-file "${ENV_FILE}" -f "${ROOT_DIR}/docker-compose.yml" -f "${ROOT_DIR}/docker-compose.prod.yml")

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Fichier d'environnement introuvable: ${ENV_FILE}" >&2
  exit 1
fi

"${COMPOSE_CMD[@]}" up -d nginx

"${COMPOSE_CMD[@]}" --profile certbot run --rm certbot renew --webroot -w /var/www/certbot

ENV_FILE="$(basename "${ENV_FILE}")" "${ROOT_DIR}/scripts/sync-letsencrypt-certs.sh"
"${COMPOSE_CMD[@]}" exec nginx nginx -s reload

echo "Renouvellement Let's Encrypt termine."
