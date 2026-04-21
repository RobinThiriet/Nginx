#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/${ENV_FILE:-.env.prod}"
COMPOSE_CMD=(docker compose --env-file "${ENV_FILE}" -f "${ROOT_DIR}/docker-compose.yml" -f "${ROOT_DIR}/docker-compose.prod.yml")

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Fichier d'environnement introuvable: ${ENV_FILE}" >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

if [[ "${NGINX_SERVER_NAME}" == "example.com" || "${STATIC_SERVER_NAME}" == "static.example.com" ]]; then
  echo "Mettez a jour .env.prod avec vos vrais domaines avant de demander un certificat." >&2
  exit 1
fi

staging_args=()
if [[ "${LETSENCRYPT_STAGING:-true}" == "true" ]]; then
  staging_args+=(--staging)
fi

"${COMPOSE_CMD[@]}" up -d nginx

"${COMPOSE_CMD[@]}" --profile certbot run --rm certbot certonly \
  --webroot -w /var/www/certbot \
  --email "${LETSENCRYPT_EMAIL}" \
  --agree-tos \
  --no-eff-email \
  "${staging_args[@]}" \
  -d "${NGINX_SERVER_NAME}" \
  -d "${STATIC_SERVER_NAME}"

ENV_FILE="$(basename "${ENV_FILE}")" "${ROOT_DIR}/scripts/sync-letsencrypt-certs.sh"
"${COMPOSE_CMD[@]}" exec nginx nginx -s reload

echo "Demande de certificat terminee."
