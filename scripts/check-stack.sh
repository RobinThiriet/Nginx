#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/.env"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo ".env introuvable. Copiez .env.example vers .env avant de continuer." >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

check() {
  local description="$1"
  shift
  echo "==> ${description}"
  "$@"
  echo
}

check "Validation Compose" docker compose -f "${ROOT_DIR}/docker-compose.yml" config
check "Etat des services" docker compose -f "${ROOT_DIR}/docker-compose.yml" ps
check "Healthcheck HTTP" curl -fsS -H "Host: ${NGINX_SERVER_NAME}" http://127.0.0.1/healthz
check "Redirection HTTPS" curl -I -H "Host: ${NGINX_SERVER_NAME}" http://127.0.0.1/
check "Landing page HTTPS" bash -lc "curl -kfsS --resolve '${NGINX_SERVER_NAME}:443:127.0.0.1' 'https://${NGINX_SERVER_NAME}/' | sed -n '1,5p'"
check "Load balancing" bash -lc "curl -kfsS --resolve '${NGINX_SERVER_NAME}:443:127.0.0.1' 'https://${NGINX_SERVER_NAME}/app/' | sed -n '1,10p'"
check "API proxifiee" bash -lc "curl -kfsS --resolve '${NGINX_SERVER_NAME}:443:127.0.0.1' 'https://${NGINX_SERVER_NAME}/api/' | sed -n '1,20p'"
check "Cache demo" curl -kI --resolve "${NGINX_SERVER_NAME}:443:127.0.0.1" "https://${NGINX_SERVER_NAME}/cache-demo/"
check "Site statique secondaire" bash -lc "curl -kfsS --resolve '${STATIC_SERVER_NAME}:443:127.0.0.1' 'https://${STATIC_SERVER_NAME}/' | sed -n '1,5p'"
