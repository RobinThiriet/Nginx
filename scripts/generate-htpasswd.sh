#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/${ENV_FILE:-.env.dev}"
HTPASSWD_FILE="${ROOT_DIR}/nginx/auth/.htpasswd"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Fichier d'environnement introuvable. Copiez .env.dev.example vers .env.dev avant de continuer." >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

mkdir -p "$(dirname "${HTPASSWD_FILE}")"

PASSWORD_HASH="$(openssl passwd -apr1 "${ADMIN_PASSWORD}")"
printf '%s:%s\n' "${ADMIN_USERNAME}" "${PASSWORD_HASH}" > "${HTPASSWD_FILE}"

echo "Fichier .htpasswd genere pour ${ADMIN_USERNAME}"
