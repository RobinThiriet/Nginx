#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${ROOT_DIR}/${ENV_FILE:-.env.dev}"

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "Fichier d'environnement introuvable: ${ENV_FILE}" >&2
  exit 1
fi

set -a
source "${ENV_FILE}"
set +a

TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${ROOT_DIR}/backups/${COMPOSE_PROJECT_NAME}/${TIMESTAMP}"
mkdir -p "${BACKUP_DIR}"

backup_volume() {
  local volume_name="$1"
  local archive_name="$2"

  docker run --rm \
    -v "${volume_name}:/source:ro" \
    -v "${BACKUP_DIR}:/backup" \
    alpine:3.22 \
    sh -lc "tar czf /backup/${archive_name} -C /source ."
}

backup_volume "${COMPOSE_PROJECT_NAME}_grafana_data" "grafana-data.tar.gz"
backup_volume "${COMPOSE_PROJECT_NAME}_prometheus_data" "prometheus-data.tar.gz"

echo "Sauvegarde creee dans ${BACKUP_DIR}"
