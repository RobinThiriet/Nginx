#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/${ENV_FILE:-.env.prod}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Fichier d'environnement introuvable: ${ENV_FILE}" >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

LIVE_DIR="${ROOT_DIR}/certs/letsencrypt/live/${NGINX_SERVER_NAME}"

if [[ ! -f "${LIVE_DIR}/fullchain.pem" || ! -f "${LIVE_DIR}/privkey.pem" ]]; then
  echo "Certificats Let's Encrypt introuvables dans ${LIVE_DIR}" >&2
  exit 1
fi

install -m 600 "${LIVE_DIR}/fullchain.pem" "${ROOT_DIR}/certs/${NGINX_SERVER_NAME}.crt"
install -m 600 "${LIVE_DIR}/privkey.pem" "${ROOT_DIR}/certs/${NGINX_SERVER_NAME}.key"
install -m 600 "${LIVE_DIR}/fullchain.pem" "${ROOT_DIR}/certs/${STATIC_SERVER_NAME}.crt"
install -m 600 "${LIVE_DIR}/privkey.pem" "${ROOT_DIR}/certs/${STATIC_SERVER_NAME}.key"

echo "Certificats synchronises vers certs/${NGINX_SERVER_NAME}.crt et certs/${STATIC_SERVER_NAME}.crt"
