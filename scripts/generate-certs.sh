#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/${ENV_FILE:-.env.dev}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Fichier d'environnement introuvable. Copiez .env.dev.example vers .env.dev avant de continuer." >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

mkdir -p "${ROOT_DIR}/certs"

generate_cert() {
  local domain="$1"
  local key_file="${ROOT_DIR}/certs/${domain}.key"
  local crt_file="${ROOT_DIR}/certs/${domain}.crt"

  if [[ -f "${key_file}" && -f "${crt_file}" ]]; then
    echo "Certificat deja present pour ${domain}"
    return
  fi

  openssl req -x509 -nodes -newkey rsa:4096 -sha256 -days 825 \
    -keyout "${key_file}" \
    -out "${crt_file}" \
    -subj "/C=${TLS_COUNTRY}/ST=${TLS_STATE}/L=${TLS_CITY}/O=${TLS_ORGANIZATION}/OU=${TLS_ORGANIZATIONAL_UNIT}/CN=${domain}/emailAddress=${TLS_EMAIL}" \
    -addext "subjectAltName = DNS:${domain},DNS:localhost,IP:127.0.0.1"

  echo "Certificat genere pour ${domain}"
}

generate_cert "${NGINX_SERVER_NAME}"
generate_cert "${STATIC_SERVER_NAME}"
